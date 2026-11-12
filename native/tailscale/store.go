package tsbridge

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sync"

	"tailscale.com/ipn"
)

// encryptedStore keeps the Tailscale node state (including the node's
// private keys) in one AES-256-GCM encrypted file.
//
// The key never touches the disk in plain form: the app keeps it in the
// Android Keystore-backed secure storage and hands it over on every start.
// A copy of the app's files is therefore useless on another device.
type encryptedStore struct {
	mu    sync.Mutex
	path  string
	aead  cipher.AEAD
	state map[ipn.StateKey][]byte
}

// newEncryptedStore opens (or creates) the store at path with a 32-byte key.
func newEncryptedStore(path string, key []byte) (*encryptedStore, error) {
	if len(key) != 32 {
		return nil, errors.New("state key must be 32 bytes")
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	aead, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}
	s := &encryptedStore{
		path:  path,
		aead:  aead,
		state: map[ipn.StateKey][]byte{},
	}
	data, err := os.ReadFile(path)
	switch {
	case errors.Is(err, os.ErrNotExist):
		return s, nil
	case err != nil:
		return nil, err
	}
	n := aead.NonceSize()
	if len(data) < n {
		return nil, errors.New("state file is truncated")
	}
	plain, err := aead.Open(nil, data[:n], data[n:], []byte(path))
	if err != nil {
		// Wrong key (another device, wiped keystore) or tampering.
		return nil, fmt.Errorf("state file cannot be decrypted: %w", err)
	}
	if err := json.Unmarshal(plain, &s.state); err != nil {
		return nil, err
	}
	return s, nil
}

func (s *encryptedStore) String() string { return "melody-encrypted-store" }

// ReadState implements ipn.StateStore.
func (s *encryptedStore) ReadState(id ipn.StateKey) ([]byte, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	v, ok := s.state[id]
	if !ok {
		return nil, ipn.ErrStateNotExist
	}
	return append([]byte(nil), v...), nil
}

// WriteState implements ipn.StateStore.
func (s *encryptedStore) WriteState(id ipn.StateKey, bs []byte) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if bs == nil {
		delete(s.state, id)
	} else {
		s.state[id] = append([]byte(nil), bs...)
	}
	return s.flushLocked()
}

func (s *encryptedStore) flushLocked() error {
	plain, err := json.Marshal(s.state)
	if err != nil {
		return err
	}
	nonce := make([]byte, s.aead.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		return err
	}
	// The path is authenticated too, so a file cannot be swapped in from
	// another location.
	sealed := s.aead.Seal(nonce, nonce, plain, []byte(s.path))
	tmp := s.path + ".tmp"
	if err := os.MkdirAll(filepath.Dir(s.path), 0o700); err != nil {
		return err
	}
	if err := os.WriteFile(tmp, sealed, 0o600); err != nil {
		return err
	}
	return os.Rename(tmp, s.path)
}

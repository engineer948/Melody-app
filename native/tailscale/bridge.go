// Package tsbridge runs a Tailscale node inside Melody (no Tailscale app,
// no VPN permission) and exposes the music server through a private
// loopback proxy. It is compiled into an Android library with gomobile.
//
// Security notes:
//   - Log upload to Tailscale is turned off (TS_NO_LOGS_NO_SUPPORT).
//   - The node state is encrypted with a key held in the Android Keystore.
//   - The node never listens on the tailnet: other devices cannot open
//     connections to the phone.
//   - The loopback proxy only answers requests carrying a random secret.
package tsbridge

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"time"

	"tailscale.com/envknob"
	"tailscale.com/ipn"
	"tailscale.com/tsnet"
)

// Status values reported by [Status].
const (
	StateStopped        = "stopped"
	StateStarting       = "starting"
	StateNeedsLogin     = "needsLogin"
	StateNeedsApproval  = "needsApproval"
	StateRunning        = "running"
	StateError          = "error"
	stateFileName       = "state.enc"
	defaultShutdownWait = 5 * time.Second
	defaultLogoutWait   = 10 * time.Second
	maxSecretLen        = 128
	minSecretLen        = 32
	maxHostnameLen      = 63
)

// controlURL overrides the coordination server in tests.
var controlURL string

// debugLogf receives backend logs (tests only).
var debugLogf = func(string, ...any) {}

type node struct {
	srv     *tsnet.Server
	http    *http.Server
	port    int
	config  string
	ready   chan struct{}
	once    sync.Once
	cancel  context.CancelFunc
	mu      sync.Mutex
	state   string
	errText string
	ip      string
}

var (
	mu      sync.Mutex
	current *node
)

func init() {
	// Nothing is sent to Tailscale's log servers, and the list of open
	// ports on the phone is never reported (also left out of the build,
	// see build_tags.txt).
	envknob.SetNoLogsNoSupport()
	os.Setenv("TS_PORTLIST", "false")
}

// Start connects to the tailnet and opens the loopback proxy to target.
//
// dir is an app-private directory, authKey is only needed for the first
// start (empty afterwards), keyHex is the 64-hex-digit state key, secret is
// the proxy's path secret and port the preferred loopback port (0 picks
// one). Returns the port the proxy listens on. Calling Start again with
// the same settings returns the running proxy.
func Start(dir, authKey, hostname, target, secret string, port int, keyHex string) (_ int, err error) {
	defer recoverTo(&err)
	mu.Lock()
	defer mu.Unlock()
	config := dir + "\x00" + target + "\x00" + secret
	if current != nil {
		if current.config == config {
			return current.port, nil
		}
		current.stop()
		current = nil
	}

	targetURL, err := url.Parse(target)
	if err != nil || (targetURL.Scheme != "http" && targetURL.Scheme != "https") || targetURL.Host == "" {
		return 0, errors.New("invalid server address")
	}
	if len(secret) < minSecretLen || len(secret) > maxSecretLen {
		return 0, errors.New("invalid proxy secret")
	}
	if hostname == "" || len(hostname) > maxHostnameLen {
		return 0, errors.New("invalid hostname")
	}
	key, err := hex.DecodeString(keyHex)
	if err != nil {
		return 0, errors.New("invalid state key")
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return 0, err
	}
	store, err := newEncryptedStore(filepath.Join(dir, stateFileName), key)
	if err != nil {
		return 0, err
	}

	ln, err := listenLoopback(port)
	if err != nil {
		return 0, err
	}
	actualPort := ln.Addr().(*net.TCPAddr).Port

	n := &node{
		config: config,
		port:   actualPort,
		ready:  make(chan struct{}),
		state:  StateStarting,
	}
	n.srv = &tsnet.Server{
		Dir:      dir,
		Store:    store,
		Hostname: hostname,
		AuthKey:  authKey,
		// Persistent node: the auth key is used once, then forgotten.
		Ephemeral:  false,
		ControlURL: controlURL,
		Logf:       debugLogf,
		UserLogf:   debugLogf,
	}
	handler := newProxyHandler(targetURL, secret, actualPort, n.srv.Dial, n.ready)
	n.http = &http.Server{
		Handler:           handler,
		ReadHeaderTimeout: 15 * time.Second,
	}
	go func() { _ = n.http.Serve(ln) }()

	ctx, cancel := context.WithCancel(context.Background())
	n.cancel = cancel
	go n.watch(ctx)

	current = n
	return actualPort, nil
}

func listenLoopback(port int) (net.Listener, error) {
	if port > 0 && port < 65536 {
		if ln, err := net.Listen("tcp", "127.0.0.1:"+strconv.Itoa(port)); err == nil {
			return ln, nil
		}
	}
	return net.Listen("tcp", "127.0.0.1:0")
}

// watch follows the backend state until ctx ends.
func (n *node) watch(ctx context.Context) {
	defer func() {
		if r := recover(); r != nil {
			n.set(StateError, fmt.Sprintf("internal error: %v", r))
		}
	}()
	lc, err := n.srv.LocalClient()
	if err != nil {
		n.set(StateError, err.Error())
		return
	}
	// Shields up: refuse every incoming connection from the tailnet.
	if _, err := lc.EditPrefs(ctx, &ipn.MaskedPrefs{
		ShieldsUpSet: true,
		Prefs:        ipn.Prefs{ShieldsUp: true},
	}); err != nil {
		n.set(StateError, err.Error())
		return
	}
	for ctx.Err() == nil {
		watcher, err := lc.WatchIPNBus(ctx, ipn.NotifyInitialState)
		if err != nil {
			n.set(StateError, err.Error())
			select {
			case <-ctx.Done():
				return
			case <-time.After(5 * time.Second):
				continue
			}
		}
		for {
			msg, err := watcher.Next()
			if err != nil {
				break
			}
			if msg.ErrMessage != nil {
				n.set(StateError, *msg.ErrMessage)
			}
			if msg.State == nil {
				continue
			}
			switch *msg.State {
			case ipn.Running:
				ip := ""
				if st, err := lc.StatusWithoutPeers(ctx); err == nil && len(st.TailscaleIPs) > 0 {
					ip = st.TailscaleIPs[0].String()
				}
				n.mu.Lock()
				n.state, n.errText, n.ip = StateRunning, "", ip
				n.mu.Unlock()
				n.once.Do(func() { close(n.ready) })
			case ipn.NeedsLogin:
				n.setIfNotError(StateNeedsLogin)
			case ipn.NeedsMachineAuth:
				n.set(StateNeedsApproval, "")
			case ipn.Starting, ipn.NoState:
				n.setIfNotError(StateStarting)
			case ipn.Stopped:
				n.set(StateStopped, "")
			}
		}
		watcher.Close()
	}
}

func (n *node) set(state, errText string) {
	n.mu.Lock()
	defer n.mu.Unlock()
	n.state, n.errText = state, errText
}

func (n *node) setIfNotError(state string) {
	n.mu.Lock()
	defer n.mu.Unlock()
	if n.state != StateError {
		n.state = state
	}
}

func (n *node) stop() {
	n.cancel()
	ctx, cancel := context.WithTimeout(context.Background(), defaultShutdownWait)
	defer cancel()
	_ = n.http.Shutdown(ctx)
	_ = n.srv.Close()
}

type statusJSON struct {
	State string `json:"state"`
	Error string `json:"error,omitempty"`
	IP    string `json:"ip,omitempty"`
	Port  int    `json:"port,omitempty"`
}

// Status returns the current state as JSON:
// {"state": "...", "error": "...", "ip": "100.x.y.z", "port": 41641}.
func Status() (out string) {
	defer func() {
		if r := recover(); r != nil {
			out = `{"state":"error","error":"internal error"}`
		}
	}()
	mu.Lock()
	n := current
	mu.Unlock()
	s := statusJSON{State: StateStopped}
	if n != nil {
		n.mu.Lock()
		s = statusJSON{State: n.state, Error: n.errText, IP: n.ip, Port: n.port}
		n.mu.Unlock()
	}
	data, _ := json.Marshal(s)
	return string(data)
}

// Stop closes the proxy and disconnects, keeping the node's identity.
func Stop() {
	defer func() { _ = recover() }()
	mu.Lock()
	defer mu.Unlock()
	if current != nil {
		current.stop()
		current = nil
	}
}

// Logout removes this device from the tailnet (when reachable) and
// deletes everything stored in dir.
func Logout(dir string) (err error) {
	defer recoverTo(&err)
	mu.Lock()
	defer mu.Unlock()
	var logoutErr error
	if current != nil {
		if lc, err := current.srv.LocalClient(); err == nil {
			ctx, cancel := context.WithTimeout(context.Background(), defaultLogoutWait)
			logoutErr = lc.Logout(ctx)
			cancel()
		}
		current.stop()
		current = nil
	}
	if err := os.RemoveAll(dir); err != nil {
		return fmt.Errorf("deleting state: %w", err)
	}
	return logoutErr
}

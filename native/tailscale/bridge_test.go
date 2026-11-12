package tsbridge

import (
	"bytes"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"tailscale.com/ipn"
)

const testSecret = "0123456789abcdef0123456789abcdef"

func testProxy(t *testing.T, ready chan struct{}) (*proxyHandler, *httptest.Server) {
	t.Helper()
	backend := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("X-Forwarded-For") != "" {
			t.Error("X-Forwarded-For leaked to the server")
		}
		if r.URL.Path == "/redirect" {
			http.Redirect(w, r, "http://"+r.Host+"/System/Info", http.StatusFound)
			return
		}
		io.WriteString(w, r.Method+" "+r.URL.RequestURI())
	}))
	t.Cleanup(backend.Close)
	target, _ := url.Parse(backend.URL)
	var d net.Dialer
	h := newProxyHandler(target, testSecret, 41641, d.DialContext, ready)
	return h, backend
}

func do(h http.Handler, host, path string) *httptest.ResponseRecorder {
	r := httptest.NewRequest(http.MethodGet, "http://"+host+path, nil)
	r.Host = host
	w := httptest.NewRecorder()
	h.ServeHTTP(w, r)
	return w
}

func TestProxyForwardsWithSecret(t *testing.T) {
	ready := make(chan struct{})
	close(ready)
	h, _ := testProxy(t, ready)
	w := do(h, "127.0.0.1:41641", "/"+testSecret+"/Items/1?api_key=x")
	if w.Code != 200 || w.Body.String() != "GET /Items/1?api_key=x" {
		t.Fatalf("got %d %q", w.Code, w.Body.String())
	}
	w = do(h, "127.0.0.1:41641", "/"+testSecret)
	if w.Code != 200 || w.Body.String() != "GET /" {
		t.Fatalf("root: got %d %q", w.Code, w.Body.String())
	}
}

func TestProxyRejectsWithoutSecret(t *testing.T) {
	ready := make(chan struct{})
	close(ready)
	h, _ := testProxy(t, ready)
	for _, path := range []string{
		"/Items/1",
		"/" + testSecret[:31] + "/Items",
		"/" + testSecret + "x/Items",
		"/" + strings.ToUpper(testSecret) + "/Items",
	} {
		if w := do(h, "127.0.0.1:41641", path); w.Code != http.StatusNotFound {
			t.Errorf("%s: got %d, want 404", path, w.Code)
		}
	}
}

func TestProxyRejectsForeignHost(t *testing.T) {
	ready := make(chan struct{})
	close(ready)
	h, _ := testProxy(t, ready)
	for _, host := range []string{"evil.example:41641", "127.0.0.1:1234", "192.168.1.5:41641"} {
		if w := do(h, host, "/"+testSecret+"/x"); w.Code != http.StatusNotFound {
			t.Errorf("%s: got %d, want 404", host, w.Code)
		}
	}
	if w := do(h, "localhost:41641", "/"+testSecret+"/x"); w.Code != 200 {
		t.Errorf("localhost: got %d", w.Code)
	}
}

func TestProxyRewritesRedirects(t *testing.T) {
	ready := make(chan struct{})
	close(ready)
	h, _ := testProxy(t, ready)
	w := do(h, "127.0.0.1:41641", "/"+testSecret+"/redirect")
	want := "http://127.0.0.1:41641/" + testSecret + "/System/Info"
	if got := w.Header().Get("Location"); got != want {
		t.Fatalf("Location %q, want %q", got, want)
	}
}

func TestProxyWaitsForTailnet(t *testing.T) {
	h, _ := testProxy(t, make(chan struct{}))
	h.wait = 50 * time.Millisecond
	if w := do(h, "127.0.0.1:41641", "/"+testSecret+"/x"); w.Code != http.StatusServiceUnavailable {
		t.Fatalf("got %d, want 503", w.Code)
	}
}

func TestEncryptedStoreRoundTrip(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "state.enc")
	key := bytes.Repeat([]byte{7}, 32)
	s, err := newEncryptedStore(path, key)
	if err != nil {
		t.Fatal(err)
	}
	secret := []byte("node-private-key-material")
	if err := s.WriteState("profile", secret); err != nil {
		t.Fatal(err)
	}
	raw, _ := os.ReadFile(path)
	if bytes.Contains(raw, secret) || bytes.Contains(raw, []byte("profile")) {
		t.Fatal("state file is not encrypted")
	}
	again, err := newEncryptedStore(path, key)
	if err != nil {
		t.Fatal(err)
	}
	got, err := again.ReadState("profile")
	if err != nil || !bytes.Equal(got, secret) {
		t.Fatalf("got %q, %v", got, err)
	}
	if err := again.WriteState("profile", nil); err != nil {
		t.Fatal(err)
	}
	if _, err := again.ReadState("profile"); err != ipn.ErrStateNotExist {
		t.Fatalf("deleted key: %v", err)
	}
}

func TestEncryptedStoreWrongKeyOrMovedFile(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "state.enc")
	s, _ := newEncryptedStore(path, bytes.Repeat([]byte{1}, 32))
	_ = s.WriteState("k", []byte("v"))
	if _, err := newEncryptedStore(path, bytes.Repeat([]byte{2}, 32)); err == nil {
		t.Fatal("opened with the wrong key")
	}
	moved := filepath.Join(dir, "other.enc")
	data, _ := os.ReadFile(path)
	_ = os.WriteFile(moved, data, 0o600)
	if _, err := newEncryptedStore(moved, bytes.Repeat([]byte{1}, 32)); err == nil {
		t.Fatal("opened a file copied to another path")
	}
	if _, err := newEncryptedStore(path, []byte("short")); err == nil {
		t.Fatal("accepted a short key")
	}
}

func TestParseInterfaces(t *testing.T) {
	got, err := parseInterfaces("wlan0\t30\t1500\tum\t192.168.1.20/24,fe80::1/64\nlo\t1\t65536\tul\t127.0.0.1/8\n")
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 2 || got[0].Name != "wlan0" || got[0].Index != 30 || got[0].MTU != 1500 {
		t.Fatalf("got %+v", got)
	}
	if got[0].Flags&net.FlagUp == 0 || got[1].Flags&net.FlagLoopback == 0 {
		t.Fatal("flags not parsed")
	}
	if len(got[0].AltAddrs) != 2 || got[0].AltAddrs[0].String() != "192.168.1.20/24" {
		t.Fatalf("addrs %v", got[0].AltAddrs)
	}
	if _, err := parseInterfaces("bad line"); err == nil {
		t.Fatal("accepted a bad line")
	}
}

func TestStartValidatesInput(t *testing.T) {
	dir := t.TempDir()
	key := strings.Repeat("ab", 32)
	cases := []struct{ target, secret, host, key string }{
		{"ftp://100.64.0.1", testSecret, "melody-x", key},
		{"http://100.64.0.1:8096", "short", "melody-x", key},
		{"http://100.64.0.1:8096", testSecret, "", key},
		{"http://100.64.0.1:8096", testSecret, "melody-x", "zz"},
	}
	for _, c := range cases {
		if _, err := Start(dir, "", c.host, c.target, c.secret, 0, c.key); err == nil {
			t.Errorf("accepted %+v", c)
		}
	}
	if s := Status(); !strings.Contains(s, `"stopped"`) {
		t.Errorf("status %s", s)
	}
}

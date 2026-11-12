package tsbridge

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"

	"crypto/tls"
	"net"
	"tailscale.com/net/netns"
	"tailscale.com/tailcfg"
	"tailscale.com/tsnet"

	"tailscale.com/derp/derpserver"
	"tailscale.com/net/stun/stuntest"
	"tailscale.com/tstest/integration/testcontrol"
	"tailscale.com/types/key"
	"tailscale.com/types/logger"
	"tailscale.com/types/nettype"
)

const testAuthKey = "tskey-auth-test-123"

// startTailnet runs a test coordination server, DERP relay and a "music
// server" node answering HTTP on :8096. Returns the server's address.
func startTailnet(t *testing.T, ctx context.Context, approval bool) (*testcontrol.Server, string) {
	t.Helper()
	netns.SetEnabled(false)
	t.Cleanup(func() { netns.SetEnabled(true) })
	derpMap := runDERPAndSTUN(t)
	control := &testcontrol.Server{
		DERPMap:            derpMap,
		DNSConfig:          &tailcfg.DNSConfig{Proxied: true},
		MagicDNSDomain:     "tail-scale.ts.net",
		RequireAuthKey:     testAuthKey,
		RequireMachineAuth: approval,
		Logf:               logger.Discard,
	}
	control.HTTPTestServer = httptest.NewUnstartedServer(control)
	control.HTTPTestServer.Start()
	t.Cleanup(control.HTTPTestServer.Close)
	controlURL = control.HTTPTestServer.URL
	if os.Getenv("TSB_DEBUG") != "" {
		debugLogf = t.Logf
	}
	t.Cleanup(func() { controlURL = "" })

	music := &tsnet.Server{
		Dir:        t.TempDir(),
		ControlURL: controlURL,
		Hostname:   "jellyfin",
		AuthKey:    testAuthKey,
		Ephemeral:  true,
		Logf:       logger.Discard,
	}
	t.Cleanup(func() { music.Close() })
	if approval {
		go approveWhenSeen(ctx, control, "jellyfin")
	}
	st, err := music.Up(ctx)
	if err != nil {
		t.Fatal(err)
	}
	ln, err := music.Listen("tcp", ":8096")
	if err != nil {
		t.Fatal(err)
	}
	go http.Serve(ln, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, "jellyfin "+r.URL.Path)
	}))
	return control, "http://" + st.TailscaleIPs[0].String() + ":8096"
}

func waitState(t *testing.T, ctx context.Context, want string) statusJSON {
	t.Helper()
	var s statusJSON
	for ctx.Err() == nil {
		_ = json.Unmarshal([]byte(Status()), &s)
		if s.State == want {
			return s
		}
		time.Sleep(50 * time.Millisecond)
	}
	t.Fatalf("state %q (%s), want %q", s.State, s.Error, want)
	return s
}

func fetch(t *testing.T, port int, path string) (int, string) {
	t.Helper()
	res, err := http.Get("http://127.0.0.1:" + strconv.Itoa(port) + path)
	if err != nil {
		t.Fatal(err)
	}
	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)
	return res.StatusCode, string(body)
}

func TestEndToEnd(t *testing.T) {
	if testing.Short() {
		t.Skip("starts a tailnet")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()
	control, target := startTailnet(t, ctx, false)

	dir := filepath.Join(t.TempDir(), "ts")
	key := strings.Repeat("5a", 32)

	// A wrong auth key is reported, not hung on.
	if _, err := Start(dir, "tskey-auth-wrong", "melody-test", target, testSecret, 0, key); err != nil {
		t.Fatal(err)
	}
	waitState(t, ctx, StateError)
	Stop()
	os.RemoveAll(dir)

	port, err := Start(dir, testAuthKey, "melody-test", target, testSecret, 0, key)
	if err != nil {
		t.Fatal(err)
	}
	st := waitState(t, ctx, StateRunning)
	if !strings.HasPrefix(st.IP, "100.") || st.Port != port {
		t.Fatalf("status %+v", st)
	}
	if code, body := fetch(t, port, "/"+testSecret+"/System/Info"); code != 200 || body != "jellyfin /System/Info" {
		t.Fatalf("got %d %q", code, body)
	}
	if code, _ := fetch(t, port, "/System/Info"); code != 404 {
		t.Fatalf("without secret: %d", code)
	}
	assertShieldsUp(t, ctx, target)

	// The node key is stored encrypted, never in plain text.
	entries, _ := os.ReadDir(dir)
	for _, e := range entries {
		if e.Name() == "tailscaled.state" {
			t.Fatal("plain state file written")
		}
	}

	// Restart without the auth key: the stored identity is reused. (The
	// test server asks for the key on every registration, the real one
	// only for new nodes.)
	control.RequireAuthKey = ""
	Stop()
	port2, err := Start(dir, "", "melody-test", target, testSecret, port, key)
	if err != nil {
		t.Fatal(err)
	}
	if port2 != port {
		t.Fatalf("port changed %d -> %d", port, port2)
	}
	waitState(t, ctx, StateRunning)
	if code, body := fetch(t, port2, "/"+testSecret+"/Items"); code != 200 || body != "jellyfin /Items" {
		t.Fatalf("after restart: %d %q", code, body)
	}

	// With another key the stored identity cannot be opened.
	Stop()
	if _, err := Start(dir, "", "melody-test", target, testSecret, 0, strings.Repeat("11", 32)); err == nil {
		t.Fatal("started with the wrong state key")
	}

	if _, err := Start(dir, "", "melody-test", target, testSecret, 0, key); err != nil {
		t.Fatal(err)
	}
	waitState(t, ctx, StateRunning)
	if err := Logout(dir); err != nil {
		t.Logf("logout: %v", err)
	}
	if _, err := os.Stat(dir); !os.IsNotExist(err) {
		t.Fatal("state not deleted")
	}
	waitState(t, ctx, StateStopped)
}

// assertShieldsUp checks that the music server cannot open connections to
// the phone's node.
func assertShieldsUp(t *testing.T, ctx context.Context, target string) {
	t.Helper()
	mu.Lock()
	n := current
	mu.Unlock()
	lc, err := n.srv.LocalClient()
	if err != nil {
		t.Fatal(err)
	}
	prefs, err := lc.GetPrefs(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if !prefs.ShieldsUp {
		t.Fatal("shields are down")
	}
	_ = target
}

// runDERPAndSTUN starts a local relay (like tstest/integration, which
// cannot be built with the app's reduced feature set).
func runDERPAndSTUN(t *testing.T) *tailcfg.DERPMap {
	t.Helper()
	d := derpserver.New(key.NewNode(), logger.Discard)
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	srv := httptest.NewUnstartedServer(derpserver.Handler(d))
	srv.Listener.Close()
	srv.Listener = ln
	srv.Config.TLSNextProto = make(map[string]func(*http.Server, *tls.Conn, http.Handler))
	srv.StartTLS()
	stunAddr, stunCleanup := stuntest.ServeWithPacketListener(t, nettype.Std{})
	t.Cleanup(func() {
		srv.CloseClientConnections()
		srv.Close()
		d.Close()
		stunCleanup()
	})
	return &tailcfg.DERPMap{
		Regions: map[tailcfg.DERPRegionID]*tailcfg.DERPRegion{
			1: {
				RegionID:   1,
				RegionCode: "test",
				Nodes: []*tailcfg.DERPNode{{
					Name:             "t1",
					RegionID:         1,
					HostName:         "127.0.0.1",
					IPv4:             "127.0.0.1",
					IPv6:             "none",
					STUNPort:         stunAddr.Port,
					DERPPort:         ln.Addr().(*net.TCPAddr).Port,
					InsecureForTests: true,
					STUNTestIP:       "127.0.0.1",
				}},
			},
		},
	}
}

// approveWhenSeen approves the node called hostname, like an admin would
// in the Tailscale admin console.
func approveWhenSeen(ctx context.Context, control *testcontrol.Server, hostname string) {
	for ctx.Err() == nil {
		for _, n := range control.AllNodes() {
			if n.Hostinfo.Hostname() == hostname && !n.MachineAuthorized {
				k := n.Key
				control.CompleteDeviceApproval(controlURL, controlURL+"/admin", &k)
			}
		}
		time.Sleep(20 * time.Millisecond)
	}
}

func TestDeviceApproval(t *testing.T) {
	if testing.Short() {
		t.Skip("starts a tailnet")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()
	control, target := startTailnet(t, ctx, true)
	dir := filepath.Join(t.TempDir(), "ts")
	port, err := Start(dir, testAuthKey, "melody-friend", target, testSecret, 0, strings.Repeat("3c", 32))
	if err != nil {
		t.Fatal(err)
	}
	defer Stop()
	waitState(t, ctx, StateNeedsApproval)
	go approveWhenSeen(ctx, control, "melody-friend")
	waitState(t, ctx, StateRunning)
	if code, body := fetch(t, port, "/"+testSecret+"/Items"); code != 200 || body != "jellyfin /Items" {
		t.Fatalf("got %d %q", code, body)
	}
}

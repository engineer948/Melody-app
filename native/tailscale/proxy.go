package tsbridge

import (
	"context"
	"crypto/subtle"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strconv"
	"strings"
	"time"
)

// dialFunc opens a connection through the tailnet.
type dialFunc func(ctx context.Context, network, address string) (net.Conn, error)

// proxyHandler forwards http://127.0.0.1:<port>/<secret>/... to target.
//
// Other apps on the phone can reach 127.0.0.1 too, so every request must
// carry the random secret path prefix that only Melody knows; anything
// else gets a bare 404. The Host header must be the loopback address,
// which blocks DNS-rebinding attacks from web pages.
type proxyHandler struct {
	secret  string
	port    int
	target  *url.URL
	ready   <-chan struct{}
	wait    time.Duration
	reverse *httputil.ReverseProxy
}

func newProxyHandler(target *url.URL, secret string, port int, dial dialFunc, ready <-chan struct{}) *proxyHandler {
	h := &proxyHandler{
		secret: secret,
		port:   port,
		target: target,
		ready:  ready,
		wait:   30 * time.Second,
	}
	transport := &http.Transport{
		DialContext:         dial,
		MaxIdleConnsPerHost: 8,
		IdleConnTimeout:     90 * time.Second,
		TLSHandshakeTimeout: 15 * time.Second,
		// The server address is fixed; never use a proxy from the
		// environment.
		Proxy: nil,
	}
	h.reverse = &httputil.ReverseProxy{
		Rewrite: func(pr *httputil.ProxyRequest) {
			pr.SetURL(target)
			pr.Out.Host = target.Host
			// No X-Forwarded-* headers: the server should not learn
			// anything about the phone.
		},
		Transport: transport,
		// Audio is streamed: pass bytes on as soon as they arrive.
		FlushInterval: -1,
		ModifyResponse: func(r *http.Response) error {
			if loc := r.Header.Get("Location"); loc != "" {
				r.Header.Set("Location", h.localize(loc))
			}
			return nil
		},
		ErrorHandler: func(w http.ResponseWriter, _ *http.Request, _ error) {
			w.WriteHeader(http.StatusBadGateway)
		},
	}
	return h
}

// localize rewrites absolute redirects to the server back to the proxy.
func (h *proxyHandler) localize(location string) string {
	origin := h.target.Scheme + "://" + h.target.Host
	if !strings.HasPrefix(location, origin) {
		return location
	}
	rest := strings.TrimPrefix(location[len(origin):], strings.TrimSuffix(h.target.Path, "/"))
	return "http://127.0.0.1:" + strconv.Itoa(h.port) + "/" + h.secret + rest
}

func (h *proxyHandler) allowedHost(host string) bool {
	port := strconv.Itoa(h.port)
	return host == "127.0.0.1:"+port || host == "localhost:"+port
}

// stripSecret returns the path without the "/<secret>" prefix.
func (h *proxyHandler) stripSecret(path string) (string, bool) {
	prefix := "/" + h.secret
	if len(path) < len(prefix) {
		return "", false
	}
	if subtle.ConstantTimeCompare([]byte(path[:len(prefix)]), []byte(prefix)) != 1 {
		return "", false
	}
	rest := path[len(prefix):]
	if rest != "" && rest[0] != '/' {
		return "", false
	}
	if rest == "" {
		rest = "/"
	}
	return rest, true
}

func (h *proxyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if !h.allowedHost(r.Host) {
		http.NotFound(w, r)
		return
	}
	path, ok := h.stripSecret(r.URL.Path)
	if !ok {
		http.NotFound(w, r)
		return
	}
	select {
	case <-h.ready:
	case <-time.After(h.wait):
		w.WriteHeader(http.StatusServiceUnavailable)
		return
	case <-r.Context().Done():
		return
	}
	out := r.Clone(r.Context())
	out.URL.Path = path
	out.URL.RawPath = ""
	out.RequestURI = ""
	h.reverse.ServeHTTP(w, out)
}

package tsbridge

import (
	"os"
	"path/filepath"
)

// prepareEnv points every place Tailscale may write to into the app's
// private directory. Android apps have no $HOME, no writable /var/lib and
// no usable $TMPDIR; without this, Tailscale panics with "no safe place
// found to store log state" (logpolicy.LogsDir). Logs stay local: upload
// is disabled.
func prepareEnv(dir string) error {
	dirs := map[string]string{
		"TS_LOGS_DIR":     filepath.Join(dir, "logs"),
		"HOME":            filepath.Join(dir, "home"),
		"XDG_CACHE_HOME":  filepath.Join(dir, "cache"),
		"XDG_CONFIG_HOME": filepath.Join(dir, "config"),
		"TMPDIR":          filepath.Join(dir, "tmp"),
	}
	for name, path := range dirs {
		if err := os.MkdirAll(path, 0o700); err != nil {
			return err
		}
		if err := os.Setenv(name, path); err != nil {
			return err
		}
	}
	return nil
}

package tsbridge

import (
	"fmt"
	"os"
	"runtime/debug"
	"sync"
)

var crashOnce sync.Once

// SetCrashFile makes the Go runtime write the report of a fatal error
// (an unrecovered panic anywhere in Tailscale) to path, so the app can
// show it after the next start instead of the error being lost.
func SetCrashFile(path string) error {
	var err error
	crashOnce.Do(func() {
		var f *os.File
		f, err = os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o600)
		if err != nil {
			return
		}
		err = debug.SetCrashOutput(f, debug.CrashOptions{})
		// SetCrashOutput keeps its own duplicate of the descriptor.
		f.Close()
	})
	return err
}

// recoverTo turns a panic in an exported function into an error, so a bug
// reached from the app's call returns an error instead of killing it.
func recoverTo(err *error) {
	if r := recover(); r != nil {
		*err = fmt.Errorf("internal error: %v", r)
	}
}

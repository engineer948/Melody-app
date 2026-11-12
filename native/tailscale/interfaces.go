package tsbridge

import (
	"errors"
	"net"
	"strconv"
	"strings"

	"tailscale.com/net/netmon"
)

// InterfaceSource lists the phone's network interfaces.
//
// Android 11+ blocks Go's own way of reading them (netlink), so the app
// passes them from java.net.NetworkInterface. Each line is
// name, index, MTU, flags ("u" up, "l" loopback, "p" point-to-point,
// "m" multicast) and comma-separated CIDR addresses, separated by tabs.
type InterfaceSource interface {
	List() string
}

// SetInterfaceSource registers the app's interface lister. Call it once
// before [Start].
func SetInterfaceSource(src InterfaceSource) {
	netmon.RegisterInterfaceGetter(func() ([]netmon.Interface, error) {
		return parseInterfaces(src.List())
	})
}

func parseInterfaces(text string) ([]netmon.Interface, error) {
	var out []netmon.Interface
	for _, line := range strings.Split(text, "\n") {
		if strings.TrimSpace(line) == "" {
			continue
		}
		f := strings.Split(line, "\t")
		if len(f) != 5 {
			return nil, errors.New("bad interface line")
		}
		index, err := strconv.Atoi(f[1])
		if err != nil {
			return nil, err
		}
		mtu, err := strconv.Atoi(f[2])
		if err != nil {
			return nil, err
		}
		var flags net.Flags
		for _, c := range f[3] {
			switch c {
			case 'u':
				flags |= net.FlagUp | net.FlagRunning
			case 'l':
				flags |= net.FlagLoopback
			case 'p':
				flags |= net.FlagPointToPoint
			case 'm':
				flags |= net.FlagMulticast
			}
		}
		addrs := []net.Addr{}
		for _, a := range strings.Split(f[4], ",") {
			if a == "" {
				continue
			}
			ip, ipnet, err := net.ParseCIDR(a)
			if err != nil {
				continue
			}
			ipnet.IP = ip
			addrs = append(addrs, ipnet)
		}
		out = append(out, netmon.Interface{
			Interface: &net.Interface{Index: index, MTU: mtu, Name: f[0], Flags: flags},
			AltAddrs:  addrs,
		})
	}
	return out, nil
}

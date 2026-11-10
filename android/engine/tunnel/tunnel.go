// Package tunnel bridges an Android VpnService TUN device to the desync engine.
//
// Packets written by the OS into the TUN fd are handled by a userspace gVisor
// TCP/IP stack. When configured, TCP flows are sent through a protected local
// SOCKS5 connection so the native ByeDPI engine can apply socket-level fake/TTL,
// split, TLS-record, and disorder methods. Without a SOCKS5 address the legacy Go
// stream desynchronizer is used. UDP flows are forwarded directly through
// protected sockets, with an option to drop UDP/443.
package tunnel

import (
	"context"
	"fmt"
	"net"
	"strconv"
	"sync"
	"sync/atomic"
	"time"

	"golang.org/x/sys/unix"

	"github.com/Vidoc3000/anti-dpi-for-russia-TEST/android/engine/desync"

	"gvisor.dev/gvisor/pkg/tcpip"
	"gvisor.dev/gvisor/pkg/tcpip/adapters/gonet"
	"gvisor.dev/gvisor/pkg/tcpip/header"
	"gvisor.dev/gvisor/pkg/tcpip/link/fdbased"
	"gvisor.dev/gvisor/pkg/tcpip/network/ipv4"
	"gvisor.dev/gvisor/pkg/tcpip/network/ipv6"
	"gvisor.dev/gvisor/pkg/tcpip/stack"
	"gvisor.dev/gvisor/pkg/tcpip/transport/icmp"
	"gvisor.dev/gvisor/pkg/tcpip/transport/tcp"
	"gvisor.dev/gvisor/pkg/tcpip/transport/udp"
	"gvisor.dev/gvisor/pkg/waiter"
)

const nicID = tcpip.NICID(1)

// Options configures a Tunnel.
type Options struct {
	// FD is the TUN file descriptor from VpnService. The tunnel dups it and owns
	// the dup; the caller keeps ownership of the original.
	FD int
	// MTU of the TUN device.
	MTU int
	// Strategy is the desync strategy applied to outbound TCP.
	Strategy desync.Strategy
	// Protector protects the engine's own upstream sockets. May be nil.
	Protector desync.Protector
	// SOCKS5Addr routes TCP flows through a local strategy proxy when set.
	SOCKS5Addr string
	// BlockQUIC drops outbound UDP to port 443 so browsers fall back to TCP TLS.
	BlockQUIC bool
	// Log receives human-readable diagnostics. May be nil.
	Log func(string)
}

// Tunnel owns a running gVisor stack bound to a TUN fd.
type Tunnel struct {
	opts   Options
	stack  *stack.Stack
	dialer *desync.Dialer
	dupFD  int
	ctx    context.Context
	cancel context.CancelFunc
	log    func(string)

	closeOnce sync.Once

	tcpAttempts       atomic.Uint64
	tcpConnected      atomic.Uint64
	tcpFailed         atomic.Uint64
	tcpEndpointFailed atomic.Uint64
	tcpDialFailed     atomic.Uint64
	udpFlows          atomic.Uint64
	udpFailed         atomic.Uint64
	quicDropped       atomic.Uint64
	statsMu           sync.Mutex
	lastEvent         string
}

// Start creates the stack and begins forwarding. It returns once the stack is
// running (packet processing happens on background goroutines).
func Start(opts Options) (*Tunnel, error) {
	if opts.MTU <= 0 {
		opts.MTU = 1500
	}
	logf := opts.Log
	if logf == nil {
		logf = func(string) {}
	}

	// Dup the fd so our lifetime is independent of the caller's PFD.
	dup, err := unix.Dup(opts.FD)
	if err != nil {
		return nil, fmt.Errorf("dup tun fd: %w", err)
	}

	linkEP, err := fdbased.New(&fdbased.Options{
		FDs:            []int{dup},
		MTU:            uint32(opts.MTU),
		EthernetHeader: false, // TUN carries bare IP packets
	})
	if err != nil {
		unix.Close(dup)
		return nil, fmt.Errorf("fdbased: %w", err)
	}

	t, err := startWithLink(linkEP, opts)
	if err != nil {
		unix.Close(dup)
		return nil, err
	}
	t.dupFD = dup
	strategyName := opts.Strategy.String()
	if opts.SOCKS5Addr != "" {
		strategyName = "native SOCKS5 " + opts.SOCKS5Addr
	}
	logf("tunnel started (mtu=" + strconv.Itoa(opts.MTU) + ", strategy=" + strategyName + ")")
	return t, nil
}

// startWithLink builds and starts the stack on an arbitrary link endpoint. It is
// used by Start (fdbased) and by tests (a channel endpoint).
func startWithLink(linkEP stack.LinkEndpoint, opts Options) (*Tunnel, error) {
	if opts.MTU <= 0 {
		opts.MTU = 1500
	}
	logf := opts.Log
	if logf == nil {
		logf = func(string) {}
	}

	s := stack.New(stack.Options{
		NetworkProtocols: []stack.NetworkProtocolFactory{
			ipv4.NewProtocol, ipv6.NewProtocol,
		},
		TransportProtocols: []stack.TransportProtocolFactory{
			tcp.NewProtocol, udp.NewProtocol,
			icmp.NewProtocol4, icmp.NewProtocol6,
		},
	})

	if tcperr := s.CreateNIC(nicID, linkEP); tcperr != nil {
		s.Close()
		return nil, fmt.Errorf("create nic: %v", tcperr)
	}
	// Accept packets addressed to any IP, and allow opening sockets with any
	// source address, since we route the whole address space into this NIC.
	s.SetPromiscuousMode(nicID, true)
	s.SetSpoofing(nicID, true)
	s.SetRouteTable([]tcpip.Route{
		{Destination: header.IPv4EmptySubnet, NIC: nicID},
		{Destination: header.IPv6EmptySubnet, NIC: nicID},
	})

	ctx, cancel := context.WithCancel(context.Background())
	t := &Tunnel{
		opts:  opts,
		stack: s,
		dialer: desync.NewDialer(desync.Config{
			Strategy:   opts.Strategy,
			Protector:  opts.Protector,
			SOCKS5Addr: opts.SOCKS5Addr,
		}),
		ctx:    ctx,
		cancel: cancel,
		log:    logf,
	}

	t.installTCP()
	t.installUDP()
	return t, nil
}

func (t *Tunnel) installTCP() {
	fwd := tcp.NewForwarder(t.stack, 0, 2048, func(r *tcp.ForwarderRequest) {
		id := r.ID()
		dst := net.JoinHostPort(
			addrToIP(id.LocalAddress).String(),
			strconv.Itoa(int(id.LocalPort)),
		)
		t.tcpAttempts.Add(1)
		var wq waiter.Queue
		ep, tcperr := r.CreateEndpoint(&wq)
		if tcperr != nil {
			t.tcpFailed.Add(1)
			t.tcpEndpointFailed.Add(1)
			t.setLastEvent("TCP " + dst + " endpoint error: " + fmt.Sprint(tcperr))
			r.Complete(true)
			return
		}
		r.Complete(false)
		local := gonet.NewTCPConn(&wq, ep)

		go func() {
			dialCtx, cancel := context.WithTimeout(t.ctx, 20*time.Second)
			defer cancel()
			up, err := t.dialer.DialContext(dialCtx, "tcp", dst)
			if err != nil {
				t.tcpFailed.Add(1)
				t.tcpDialFailed.Add(1)
				t.setLastEvent("TCP " + dst + " upstream dial error: " + err.Error())
				t.log("tcp dial " + dst + ": " + err.Error())
				local.Close()
				return
			}
			t.tcpConnected.Add(1)
			t.setLastEvent(dst + " connected")
			desync.Relay(local, up)
		}()
	})
	t.stack.SetTransportProtocolHandler(tcp.ProtocolNumber, fwd.HandlePacket)
}

func (t *Tunnel) installUDP() {
	fwd := udp.NewForwarder(t.stack, func(r *udp.ForwarderRequest) bool {
		id := r.ID()
		dstIP := addrToIP(id.LocalAddress)
		dstPort := int(id.LocalPort)
		if t.opts.BlockQUIC && dstPort == 443 {
			t.quicDropped.Add(1)
			return true // consume the packet; client may retry over TCP
		}
		t.udpFlows.Add(1)
		var wq waiter.Queue
		ep, tcperr := r.CreateEndpoint(&wq)
		if tcperr != nil {
			t.udpFailed.Add(1)
			return true
		}
		local := gonet.NewUDPConn(&wq, ep)
		go t.handleUDP(local, dstIP, dstPort)
		return true
	})
	t.stack.SetTransportProtocolHandler(udp.ProtocolNumber, fwd.HandlePacket)
}

// handleUDP forwards a single UDP flow to its real destination through a
// protected socket, relaying datagrams until the flow goes idle.
func (t *Tunnel) handleUDP(local *gonet.UDPConn, dstIP net.IP, dstPort int) {
	defer local.Close()

	remote, err := dialProtectedUDP(t.ctx, dstIP, dstPort, t.opts.Protector)
	if err != nil {
		t.udpFailed.Add(1)
		t.setLastEvent("UDP " + net.JoinHostPort(dstIP.String(), strconv.Itoa(dstPort)) + " connect error: " + err.Error())
		t.log("udp dial: " + err.Error())
		return
	}
	defer remote.Close()

	const idle = 60 * time.Second
	var wg sync.WaitGroup
	wg.Add(2)
	// client -> remote
	go func() {
		defer wg.Done()
		buf := make([]byte, 64*1024)
		for {
			_ = local.SetReadDeadline(time.Now().Add(idle))
			n, err := local.Read(buf)
			if n > 0 {
				_ = remote.SetWriteDeadline(time.Now().Add(idle))
				if _, werr := remote.Write(buf[:n]); werr != nil {
					return
				}
			}
			if err != nil {
				return
			}
		}
	}()
	// remote -> client
	go func() {
		defer wg.Done()
		buf := make([]byte, 64*1024)
		for {
			_ = remote.SetReadDeadline(time.Now().Add(idle))
			n, err := remote.Read(buf)
			if n > 0 {
				if _, werr := local.Write(buf[:n]); werr != nil {
					return
				}
			}
			if err != nil {
				return
			}
		}
	}()
	wg.Wait()
}

// Stop tears down the stack and releases the dup'd fd.
func (t *Tunnel) Stop() {
	t.closeOnce.Do(func() {
		t.cancel()
		t.stack.Close()
		if t.dupFD > 0 {
			unix.Close(t.dupFD)
		}
		t.log("tunnel stopped")
	})
}

// Stats reports approximate flow counters for diagnosis. It does not indicate
// that a DPI strategy bypassed filtering; it only shows what reached the TUN
// and whether the local egress sockets connected.
func (t *Tunnel) Stats() string {
	t.statsMu.Lock()
	last := t.lastEvent
	t.statsMu.Unlock()
	return fmt.Sprintf("TCP attempts=%d connected=%d failed=%d (endpoint=%d upstream=%d); UDP flows=%d failed=%d; UDP/443 dropped=%d; last=%s",
		t.tcpAttempts.Load(), t.tcpConnected.Load(), t.tcpFailed.Load(),
		t.tcpEndpointFailed.Load(), t.tcpDialFailed.Load(),
		t.udpFlows.Load(), t.udpFailed.Load(), t.quicDropped.Load(), last)
}

func (t *Tunnel) setLastEvent(event string) {
	t.statsMu.Lock()
	t.lastEvent = event
	t.statsMu.Unlock()
}

func addrToIP(a tcpip.Address) net.IP {
	b := a.AsSlice()
	return net.IP(b)
}

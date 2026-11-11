package tunnel

import (
	"context"
	"net"

	"github.com/Vidoc3000/anti-dpi-for-russia-TEST/android/engine/desync"
)

// Egress owns transport creation for forwarded flows. Keeping it outside the
// gVisor flow manager lets the tunnel core evolve independently from its current
// local-SOCKS TCP path and protected-socket UDP path.
type Egress interface {
	DialTCP(ctx context.Context, network, address string) (net.Conn, error)
	DialUDP(ctx context.Context, ip net.IP, port int) (net.Conn, error)
}

type socketEgress struct {
	tcp       *desync.Dialer
	protector desync.Protector
}

func newSocketEgress(strategy desync.Strategy, protector desync.Protector, socks5Addr string) *socketEgress {
	return &socketEgress{
		tcp:       desync.NewDialer(desync.Config{Strategy: strategy, Protector: protector, SOCKS5Addr: socks5Addr}),
		protector: protector,
	}
}

func (e *socketEgress) DialTCP(ctx context.Context, network, address string) (net.Conn, error) {
	return e.tcp.DialContext(ctx, network, address)
}

func (e *socketEgress) DialUDP(ctx context.Context, ip net.IP, port int) (net.Conn, error) {
	return dialProtectedUDP(ctx, ip, port, e.protector)
}

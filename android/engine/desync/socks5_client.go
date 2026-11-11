package desync

import (
	"context"
	"encoding/binary"
	"fmt"
	"io"
	"net"
	"strconv"
	"time"
)

// dialSOCKS5 connects to a local SOCKS5 engine and asks it to open addr. It is
// deliberately a small no-auth CONNECT client: Android's native ByeDPI listener
// performs the real upstream dial and the DPI strategy.
func (d *Dialer) dialSOCKS5(ctx context.Context, addr string) (net.Conn, error) {
	c, err := d.nd.DialContext(ctx, "tcp", d.cfg.SOCKS5Addr)
	if err != nil {
		return nil, fmt.Errorf("dial local SOCKS5: %w", err)
	}
	ok := false
	defer func() {
		if !ok {
			_ = c.Close()
		}
	}()
	stopCancellation := context.AfterFunc(ctx, func() { _ = c.Close() })
	defer stopCancellation()

	deadline := time.Now().Add(10 * time.Second)
	if ctxDeadline, hasDeadline := ctx.Deadline(); hasDeadline && ctxDeadline.Before(deadline) {
		deadline = ctxDeadline
	}
	_ = c.SetDeadline(deadline)

	if err = writeAll(c, []byte{5, 1, 0}); err != nil {
		return nil, fmt.Errorf("SOCKS5 greeting: %w", err)
	}
	var greeting [2]byte
	if _, err = io.ReadFull(c, greeting[:]); err != nil {
		return nil, fmt.Errorf("SOCKS5 greeting response: %w", err)
	}
	if greeting[0] != 5 || greeting[1] != 0 {
		return nil, fmt.Errorf("SOCKS5 no-auth method rejected: %v", greeting)
	}

	request, err := socks5ConnectRequest(addr)
	if err != nil {
		return nil, err
	}
	if err = writeAll(c, request); err != nil {
		return nil, fmt.Errorf("SOCKS5 CONNECT request: %w", err)
	}
	var response [4]byte
	if _, err = io.ReadFull(c, response[:]); err != nil {
		return nil, fmt.Errorf("SOCKS5 CONNECT response: %w", err)
	}
	if response[0] != 5 {
		return nil, fmt.Errorf("invalid SOCKS5 response version %d", response[0])
	}
	if err = discardSOCKS5Address(c, response[3]); err != nil {
		return nil, fmt.Errorf("read SOCKS5 bound address: %w", err)
	}
	if response[1] != repSucceeded {
		return nil, fmt.Errorf("SOCKS5 CONNECT rejected: %s (code %d)", socks5ReplyName(response[1]), response[1])
	}
	_ = c.SetDeadline(time.Time{})
	ok = true
	return c, nil
}

func socks5ReplyName(code byte) string {
	switch code {
	case repGeneralFailure:
		return "general failure"
	case 0x02:
		return "connection not allowed by ruleset"
	case 0x03:
		return "network unreachable"
	case 0x04:
		return "host unreachable"
	case 0x05:
		return "connection refused"
	case 0x06:
		return "TTL expired"
	case repCommandNotSupport:
		return "command not supported"
	case repAddrTypeNotSupport:
		return "address type not supported"
	default:
		return "unknown SOCKS5 reply"
	}
}

func socks5ConnectRequest(addr string) ([]byte, error) {
	host, portText, err := net.SplitHostPort(addr)
	if err != nil {
		return nil, fmt.Errorf("invalid destination %q: %w", addr, err)
	}
	port, err := strconv.Atoi(portText)
	if err != nil || port < 1 || port > 65535 {
		return nil, fmt.Errorf("invalid destination port %q", portText)
	}

	request := []byte{5, 1, 0}
	if ip := net.ParseIP(host); ip != nil {
		if ip4 := ip.To4(); ip4 != nil {
			request = append(request, 1)
			request = append(request, ip4...)
		} else {
			request = append(request, 4)
			request = append(request, ip.To16()...)
		}
	} else {
		if len(host) == 0 || len(host) > 255 {
			return nil, fmt.Errorf("invalid SOCKS5 destination hostname length %d", len(host))
		}
		request = append(request, 3, byte(len(host)))
		request = append(request, host...)
	}
	var p [2]byte
	binary.BigEndian.PutUint16(p[:], uint16(port))
	request = append(request, p[:]...)
	return request, nil
}

func discardSOCKS5Address(r io.Reader, atyp byte) error {
	var size int
	switch atyp {
	case 1:
		size = net.IPv4len
	case 4:
		size = net.IPv6len
	case 3:
		var n [1]byte
		if _, err := io.ReadFull(r, n[:]); err != nil {
			return err
		}
		size = int(n[0])
	default:
		return fmt.Errorf("unknown address type %d", atyp)
	}
	var addressAndPort [net.IPv6len + 2]byte
	_, err := io.ReadFull(r, addressAndPort[:size+2])
	return err
}

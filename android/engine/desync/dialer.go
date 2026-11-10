package desync

import (
	"bytes"
	"context"
	"errors"
	"io"
	"net"
	"sync"
	"syscall"
	"time"

	"golang.org/x/sys/unix"
)

// Protector lets the host exclude a socket from the VPN so that the engine's own
// upstream connections do not loop back into the TUN. On Android this wraps
// VpnService.protect(fd). It may be nil in host-only tests.
type Protector interface {
	Protect(fd int) bool
}

// ErrProtectFailed is returned when the host refuses to protect a socket.
var ErrProtectFailed = errors.New("protect socket failed")

// Config configures a Dialer.
type Config struct {
	Strategy  Strategy
	Protector Protector
}

// Dialer dials upstream TCP connections that apply a stream strategy to the
// first complete TLS ClientHello or plaintext HTTP header.
type Dialer struct {
	cfg Config
	nd  net.Dialer
}

// NewDialer builds a Dialer. It sets TCP_NODELAY so requested write boundaries
// are less likely to be coalesced, and protects every upstream socket.
func NewDialer(cfg Config) *Dialer {
	d := &Dialer{cfg: cfg}
	d.nd.Control = func(network, address string, c syscall.RawConn) error {
		var perr error
		cerr := c.Control(func(fd uintptr) {
			_ = unix.SetsockoptInt(int(fd), unix.IPPROTO_TCP, unix.TCP_NODELAY, 1)
			// Fail closed: an unprotected socket could be routed back into the TUN.
			if cfg.Protector != nil && !cfg.Protector.Protect(int(fd)) {
				perr = ErrProtectFailed
			}
		})
		if cerr != nil {
			return cerr
		}
		return perr
	}
	return d
}

// DialContext dials addr and returns a connection that buffers enough of the
// first payload to avoid losing a ClientHello split across TUN reads.
func (d *Dialer) DialContext(ctx context.Context, network, addr string) (net.Conn, error) {
	c, err := d.nd.DialContext(ctx, network, addr)
	if err != nil {
		return nil, err
	}
	return &desyncConn{Conn: c, strat: d.cfg.Strategy}, nil
}

const maxFirstPayload = 64 * 1024

// desyncConn applies the strategy once to the first complete TLS record or HTTP
// header, and passes later bytes through unchanged.
type desyncConn struct {
	net.Conn
	strat     Strategy
	mu        sync.Mutex
	firstDone bool
	pending   []byte
}

func (c *desyncConn) Write(b []byte) (int, error) {
	if len(b) == 0 {
		return 0, nil
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.firstDone {
		return c.Conn.Write(b)
	}

	c.pending = append(c.pending, b...)
	if len(c.pending) > maxFirstPayload {
		c.firstDone = true
		data := c.pending
		c.pending = nil
		return len(b), writeAll(c.Conn, data)
	}
	if !firstPayloadComplete(c.pending) {
		// These bytes are accepted into our bounded preface buffer. The upstream
		// socket is written as soon as a full hello/header is available.
		return len(b), nil
	}

	c.firstDone = true
	data := c.pending
	c.pending = nil
	_, err := c.writeFirst(data)
	return len(b), err
}

func firstPayloadComplete(b []byte) bool {
	if len(b) == 0 {
		return false
	}
	if b[0] == 0x16 {
		if len(b) < 2 {
			return false
		}
		if b[1] == 0x03 {
			if len(b) < 5 {
				return false
			}
			recordLength := int(b[3])<<8 | int(b[4])
			if recordLength == 0 {
				return true
			}
			if len(b) < 6 {
				return false
			}
			if b[5] != 0x01 { // handshake record does not start with ClientHello
				return true
			}
			if recordLength > maxFirstPayload-5 {
				return true
			}
			return len(b) >= 5+recordLength
		}
	}

	if isHTTPMethodPrefix(b) {
		return bytes.Contains(b, []byte("\r\n\r\n")) || len(b) >= maxFirstPayload
	}
	return true
}

func isHTTPMethodPrefix(b []byte) bool {
	for _, method := range [][]byte{
		[]byte("GET "), []byte("POST "), []byte("HEAD "), []byte("PUT "),
		[]byte("DELETE "), []byte("OPTIONS "), []byte("CONNECT "),
		[]byte("PATCH "), []byte("TRACE "), []byte("PRI * HTTP/2.0"),
	} {
		if bytes.HasPrefix(method, b) || bytes.HasPrefix(b, method) {
			return true
		}
	}
	return false
}

func writeAll(dst io.Writer, b []byte) error {
	for len(b) > 0 {
		n, err := dst.Write(b)
		if n > 0 {
			b = b[n:]
		}
		if err != nil {
			return err
		}
		if n == 0 {
			return io.ErrShortWrite
		}
	}
	return nil
}

// CloseWrite forwards a half-close after flushing any incomplete buffered
// preface unchanged, preserving ordinary TCP stream semantics.
func (c *desyncConn) CloseWrite() error {
	if err := c.flushPending(); err != nil {
		return err
	}
	if hc, ok := c.Conn.(halfCloser); ok {
		return hc.CloseWrite()
	}
	return nil
}

func (c *desyncConn) Close() error {
	flushErr := c.flushPending()
	closeErr := c.Conn.Close()
	if flushErr != nil {
		return flushErr
	}
	return closeErr
}

func (c *desyncConn) flushPending() error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.firstDone || len(c.pending) == 0 {
		return nil
	}
	c.firstDone = true
	data := c.pending
	c.pending = nil
	return writeAll(c.Conn, data)
}

func (c *desyncConn) writeFirst(b []byte) (int, error) {
	segs := BuildSegments(b, c.strat)
	total := 0
	for i, s := range segs {
		if i > 0 && c.strat.SegDelayMs > 0 {
			time.Sleep(time.Duration(c.strat.SegDelayMs) * time.Millisecond)
		}
		if s.OOB {
			if len(s.Data) > 0 {
				_ = c.sendOOB(s.Data[0])
			}
			continue
		}
		if err := writeAll(c.Conn, s.Data); err != nil {
			return total, err
		}
		total += len(s.Data)
	}
	return total, nil
}

// sendOOB writes a single byte as TCP urgent (out-of-band) data, integrating
// with the runtime network poller so it respects writability.
func (c *desyncConn) sendOOB(bt byte) error {
	sc, ok := c.Conn.(syscall.Conn)
	if !ok {
		return nil
	}
	raw, err := sc.SyscallConn()
	if err != nil {
		return err
	}
	var serr error
	werr := raw.Write(func(fd uintptr) bool {
		e := unix.Send(int(fd), []byte{bt}, unix.MSG_OOB)
		if e == unix.EAGAIN {
			return false
		}
		serr = e
		return true
	})
	if werr != nil {
		return werr
	}
	return serr
}

package desync

import (
	"context"
	"io"
	"net"
	"strconv"
	"testing"
	"time"
)

func TestDialerRoutesThroughLocalSOCKS5(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()

	serverErr := make(chan error, 1)
	go func() {
		client, err := listener.Accept()
		if err != nil {
			serverErr <- err
			return
		}
		defer client.Close()
		_ = client.SetDeadline(time.Now().Add(3 * time.Second))
		greeting := make([]byte, 3)
		if _, err = io.ReadFull(client, greeting); err != nil {
			serverErr <- err
			return
		}
		if string(greeting) != string([]byte{5, 1, 0}) {
			serverErr <- errUnexpectedSOCKSData("greeting", greeting)
			return
		}
		if _, err = client.Write([]byte{5, 0}); err != nil {
			serverErr <- err
			return
		}
		request := make([]byte, 10) // IPv4 CONNECT to 203.0.113.7:443.
		if _, err = io.ReadFull(client, request); err != nil {
			serverErr <- err
			return
		}
		wantRequest := []byte{5, 1, 0, 1, 203, 0, 113, 7, 1, 187}
		for i := range wantRequest {
			if request[i] != wantRequest[i] {
				serverErr <- errUnexpectedSOCKSData("CONNECT", request)
				return
			}
		}
		if _, err = client.Write([]byte{5, 0, 0, 1, 127, 0, 0, 1, 0, 0}); err != nil {
			serverErr <- err
			return
		}
		payload := make([]byte, 4)
		if _, err = io.ReadFull(client, payload); err != nil {
			serverErr <- err
			return
		}
		_, err = client.Write(payload)
		serverErr <- err
	}()

	strategy, _ := ParseStrategy("none")
	dialer := NewDialer(Config{Strategy: strategy, SOCKS5Addr: listener.Addr().String()})
	conn, err := dialer.DialContext(context.Background(), "tcp", net.JoinHostPort("203.0.113.7", strconv.Itoa(443)))
	if err != nil {
		t.Fatal(err)
	}
	defer conn.Close()
	_ = conn.SetDeadline(time.Now().Add(3 * time.Second))
	if _, err := conn.Write([]byte("ping")); err != nil {
		t.Fatal(err)
	}
	got := make([]byte, 4)
	if _, err := io.ReadFull(conn, got); err != nil {
		t.Fatal(err)
	}
	if string(got) != "ping" {
		t.Fatalf("SOCKS tunneled payload = %q, want ping", got)
	}
	if err := <-serverErr; err != nil {
		t.Fatal(err)
	}
}

func errUnexpectedSOCKSData(stage string, got []byte) error {
	return &unexpectedSOCKSData{stage: stage, got: append([]byte(nil), got...)}
}

type unexpectedSOCKSData struct {
	stage string
	got   []byte
}

func (e *unexpectedSOCKSData) Error() string {
	return "unexpected SOCKS5 " + e.stage + " bytes: " + string(e.got)
}

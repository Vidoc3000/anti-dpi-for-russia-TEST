package desync

import (
	"bytes"
	"crypto/tls"
	"errors"
	"io"
	"net"
	"testing"
	"time"
)

func TestTLSRecordFragmentIsAcceptedByGoTLSParser(t *testing.T) {
	clientSide, serverSide := net.Pipe()
	defer clientSide.Close()
	defer serverSide.Close()
	_ = clientSide.SetDeadline(time.Now().Add(5 * time.Second))
	_ = serverSide.SetDeadline(time.Now().Add(5 * time.Second))

	seenSNI := make(chan string, 1)
	server := tls.Server(serverSide, &tls.Config{
		GetConfigForClient: func(hello *tls.ClientHelloInfo) (*tls.Config, error) {
			seenSNI <- hello.ServerName
			return nil, errors.New("stop after confirming ClientHello parse")
		},
	})
	go func() { _ = server.Handshake() }()

	conn := &desyncConn{Conn: clientSide, strat: Default()}
	client := tls.Client(conn, &tls.Config{ServerName: "www.example.com", InsecureSkipVerify: true})
	_ = client.Handshake() // The server deliberately aborts after parsing ClientHello.
	select {
	case sni := <-seenSNI:
		if sni != "www.example.com" {
			t.Fatalf("server parsed SNI %q, want www.example.com", sni)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("Go TLS server did not parse the fragmented ClientHello")
	}
}

func TestDialerBuffersSplitClientHelloBeforeTransform(t *testing.T) {
	clientSide, serverSide := net.Pipe()
	defer clientSide.Close()
	defer serverSide.Close()

	conn := &desyncConn{Conn: clientSide, strat: Default()}
	original := captureClientHello(t, "www.example.com")
	if len(original) < 10 {
		t.Fatalf("captured ClientHello is unexpectedly short: %d", len(original))
	}

	if n, err := conn.Write(original[:3]); err != nil || n != 3 {
		t.Fatalf("first partial Write() = (%d, %v), want (3, nil)", n, err)
	}

	gotCh := make(chan []byte, 1)
	errCh := make(chan error, 1)
	go func() {
		wire := make([]byte, len(original)+5)
		_, err := io.ReadFull(serverSide, wire)
		if err != nil {
			errCh <- err
			return
		}
		gotCh <- wire
	}()

	if n, err := conn.Write(original[3:]); err != nil || n != len(original)-3 {
		t.Fatalf("remaining Write() = (%d, %v), want (%d, nil)", n, err, len(original)-3)
	}
	select {
	case err := <-errCh:
		t.Fatal(err)
	case wire := <-gotCh:
		if !bytes.Equal(reassembleHandshake(t, wire), reassembleHandshake(t, original)) {
			t.Fatal("fragmented TUN reads changed the server-visible ClientHello")
		}
		if countRecords(wire) < 2 {
			t.Fatal("expected transformed ClientHello to contain multiple TLS records")
		}
	}
}

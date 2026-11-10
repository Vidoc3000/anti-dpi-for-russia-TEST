package zapret

import "testing"

func TestAdaptZapretArgsKeepsOnlyStreamSafeOperations(t *testing.T) {
	args := `[
		"--payload=tls_client_hello",
		"--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1",
		"--lua-desync=multisplit:pos=1,midsld,sniext+1,midsld-2,midsld+2,endhost-1"
	]`
	got := AdaptZapretArgs(args)
	want := "tlsrec:sni,split:1,split:sni,split:sni+1,split:sni-2,split:sni+2,split:sni-1"
	if got != want {
		t.Fatalf("AdaptZapretArgs() = %q, want %q", got, want)
	}
}

func TestAdaptZapretArgsRejectsMalformedAndCapsSplits(t *testing.T) {
	if got := AdaptZapretArgs("not JSON"); got != "tlsrec:sni" {
		t.Fatalf("malformed args fallback = %q", got)
	}
	args := `{"not":"an array"}`
	if got := AdaptZapretArgs(args); got != "tlsrec:sni" {
		t.Fatalf("wrong JSON shape fallback = %q", got)
	}
}

func TestAdaptZapretArgsSkipsUnsupportedOnlyRecipe(t *testing.T) {
	args := `["--lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000",
	         "--lua-desync=multidisorder:pos=1,midsld:seqovl=1"]`
	if got := AdaptZapretArgs(args); got != "tlsrec:sni" {
		t.Fatalf("unsupported recipe fallback = %q", got)
	}
}

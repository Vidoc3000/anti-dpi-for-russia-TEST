package zapret

import (
	"encoding/json"
	"os"
	"reflect"
	"testing"
)

func TestAdaptByeDpiArgsMapsFakeAndSplit(t *testing.T) {
	args := `["--payload=tls_client_hello",
		"--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1",
		"--lua-desync=multisplit:pos=1,midsld,sniext+1"]`
	got := adaptByeDpiArgs(args, 10808)
	want := []string{
		"--ip", "127.0.0.1", "--port", "10808",
		"--fake", "0+sm", "--split", "1", "--split", "0+sm", "--split", "1+s",
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("adaptByeDpiArgs() = %#v, want %#v", got, want)
	}
}

func TestAdaptByeDpiArgsUsesTLSRecordFragmentWithoutOtherDesync(t *testing.T) {
	got := adaptByeDpiArgs(`[]`, 10808)
	want := []string{"--ip", "127.0.0.1", "--port", "10808", "--tlsrec", "0+sm"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("TLS-only fallback = %#v, want %#v", got, want)
	}
}

func TestAdaptByeDpiArgsCoversAndroidCatalogue(t *testing.T) {
	data, err := os.ReadFile("../../app/src/main/assets/catalogue.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalogue struct {
		ProfileRows []struct {
			Args []string
		} `json:"ProfileRows"`
	}
	if err := json.Unmarshal(data, &catalogue); err != nil {
		t.Fatal(err)
	}
	if len(catalogue.ProfileRows) != 492 {
		t.Fatalf("catalogue profiles = %d, want 492", len(catalogue.ProfileRows))
	}
	for index, profile := range catalogue.ProfileRows {
		encoded, err := json.Marshal(profile.Args)
		if err != nil {
			t.Fatal(err)
		}
		got := adaptByeDpiArgs(string(encoded), 10808)
		if len(got) < 4 || got[0] != "--ip" || got[2] != "--port" {
			t.Fatalf("profile %d produced malformed native arguments: %#v", index+1, got)
		}
		for i := 4; i < len(got); i += 2 {
			if i+1 >= len(got) {
				t.Fatalf("profile %d has unpaired native argument: %#v", index+1, got)
			}
			switch got[i] {
			case "--tlsrec", "--fake", "--split", "--disorder", "--hosts":
			default:
				t.Fatalf("profile %d produced unsupported native flag %q", index+1, got[i])
			}
		}
	}
}

func TestAdaptByeDpiArgsMapsFakedDisorderAndHostFilter(t *testing.T) {
	args := `["--lua-desync=fakeddisorder:pos=1,midsld:tcp_seq=1000000",
		"--lua-desync=hostfakesplit:host=example.org:midhost=midsld"]`
	got := adaptByeDpiArgs(args, 0)
	want := []string{
		"--ip", "127.0.0.1", "--port", "10808",
		"--fake", "1", "--disorder", "0+sm",
		"--hosts", ":example.org", "--fake", "0+hm",
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("adaptByeDpiArgs() = %#v, want %#v", got, want)
	}
}

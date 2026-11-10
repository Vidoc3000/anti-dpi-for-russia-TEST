package zapret

import (
	"encoding/json"
	"strconv"
	"strings"
)

// AdaptZapretArgs returns the Android-safe, stream-level interpretation of one
// desktop Zapret2 recipe's JSON-encoded Args array. Raw fake packets, TCP sequence/
// timestamp spoofing, SYN tricks, window-size changes, and actual reordering are
// intentionally omitted: an unprivileged VpnService cannot perform those safely.
// The result always includes TLS-record fragmentation; recognized split points
// are added as best-effort TCP write boundaries.
func adaptZapretArgs(encodedArgs string) string {
	var args []string
	if err := json.Unmarshal([]byte(encodedArgs), &args); err != nil {
		return "tlsrec:sni"
	}

	steps := []string{"tlsrec:sni"}
	seen := map[string]bool{}
	for _, arg := range args {
		if !strings.HasPrefix(arg, "--lua-desync=") {
			continue
		}
		spec := strings.TrimPrefix(arg, "--lua-desync=")
		colon := strings.IndexByte(spec, ':')
		if colon < 0 {
			continue
		}
		method, params := spec[:colon], spec[colon+1:]
		if method != "multisplit" && method != "fakedsplit" && method != "tcpseg" {
			continue
		}
		pos := ""
		for _, part := range strings.Split(params, ":") {
			if strings.HasPrefix(part, "pos=") {
				pos = strings.TrimPrefix(part, "pos=")
				break
			}
		}
		if pos == "" {
			continue
		}
		for _, token := range strings.Split(pos, ",") {
			mapped, ok := androidSplitPosition(token)
			if !ok || seen[mapped] || len(steps) >= 9 {
				continue
			}
			seen[mapped] = true
			steps = append(steps, "split:"+mapped)
		}
	}
	return strings.Join(steps, ",")
}

func androidSplitPosition(token string) (string, bool) {
	token = strings.TrimSpace(strings.ToLower(token))
	switch token {
	case "midsld":
		return "sni", true
	case "sniext+1", "host+1":
		return "sni+1", true
	case "sniext+4":
		return "sni+4", true
	case "midsld-2":
		return "sni-2", true
	case "midsld+2":
		return "sni+2", true
	case "endhost-1":
		// The mobile parser positions around the middle of SNI, not its end.
		// Keep the offset conservative and disclose this approximation in the UI.
		return "sni-1", true
	}
	if n, err := strconv.Atoi(token); err == nil {
		if n <= 0 {
			n = 1
		}
		if n > 8192 {
			n = 8192
		}
		return strconv.Itoa(n), true
	}
	return "", false
}

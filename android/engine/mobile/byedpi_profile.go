package zapret

import (
	"encoding/json"
	"strconv"
	"strings"
)

// AdaptByeDpiArgs translates supported stream-relevant parts of one Zapret2
// catalogue row to a JSON string array for the local native ByeDPI SOCKS
// worker. It remains an approximation: raw packet injection, arbitrary TCP
// option edits, SYN data, window-size changes, and custom fake blobs are not
// byte-for-byte equivalent in this engine.
func AdaptByeDpiArgs(encodedArgs string, listenPort int) string {
	encoded, _ := json.Marshal(adaptByeDpiArgs(encodedArgs, listenPort))
	return string(encoded)
}

func adaptByeDpiArgs(encodedArgs string, listenPort int) []string {
	if listenPort < 1 || listenPort > 65535 {
		listenPort = 10808
	}
	var args []string
	if json.Unmarshal([]byte(encodedArgs), &args) != nil {
		return []string{"--ip", "127.0.0.1", "--port", strconv.Itoa(listenPort), "--tlsrec", "0+sm"}
	}
	hasNativeDesync := false
	for _, arg := range args {
		if !strings.HasPrefix(arg, "--lua-desync=") {
			continue
		}
		method, _, ok := parseZapretDesync(strings.TrimPrefix(arg, "--lua-desync="))
		if !ok {
			continue
		}
		switch method {
		case "fake", "multisplit", "tcpseg", "fakedsplit", "fakeddisorder", "multidisorder", "hostfakesplit":
			hasNativeDesync = true
		}
	}
	out := []string{"--ip", "127.0.0.1", "--port", strconv.Itoa(listenPort)}
	// ByteDPI transforms TLS records before TCP split/fake processing. Keep the
	// original ClientHello intact whenever the profile also needs position-based
	// processing; otherwise SNI offsets could be lost after record fragmentation.
	if !hasNativeDesync {
		out = append(out, "--tlsrec", "0+sm")
	}

	for _, arg := range args {
		if !strings.HasPrefix(arg, "--lua-desync=") {
			continue
		}
		method, fields, ok := parseZapretDesync(strings.TrimPrefix(arg, "--lua-desync="))
		if !ok {
			continue
		}
		positions := splitZapretPositions(fields["pos"])
		if fields["host"] != "" && method == "hostfakesplit" {
			out = append(out, "--hosts", ":"+fields["host"])
		}
		if method == "fake" || method == "fakedsplit" || method == "fakeddisorder" || method == "hostfakesplit" {
			if ttl := validNativeTTL(fields["ip_ttl"]); ttl != "" {
				out = append(out, "--ttl", ttl)
			}
			if sni := tlsModSNI(fields["tls_mod"]); sni != "" {
				out = append(out, "--fake-sni", sni)
			}
			if data := hexBlobArgument(fields["blob"]); data != "" {
				out = append(out, "--fake-data", data)
			}
		}
		switch method {
		case "fake":
			// ByeDPI's native fake is injected with low TTL and lets the kernel
			// retransmit the real queued bytes. The exact Zapret blob/TCP options
			// are intentionally not claimed as equivalent.
			out = append(out, "--fake", "0+sm")
		case "multisplit", "tcpseg":
			if method == "multisplit" && nativeFakeBlob(fields["blob"]) && len(positions) > 0 {
				if ttl := validNativeTTL(fields["ip_ttl"]); ttl != "" {
					out = append(out, "--ttl", ttl)
				}
				if sni := tlsModSNI(fields["tls_mod"]); sni != "" {
					out = append(out, "--fake-sni", sni)
				}
				if data := hexBlobArgument(fields["blob"]); data != "" {
					out = append(out, "--fake-data", data)
				}
				out = append(out, "--fake", mapByeDpiPosition(positions[0]))
				positions = positions[1:]
			}
			for _, position := range positions {
				out = append(out, "--split", mapByeDpiPosition(position))
			}
		case "fakedsplit", "hostfakesplit":
			if method == "hostfakesplit" {
				if len(positions) == 0 {
					positions = []string{fields["midhost"]}
				}
			}
			if len(positions) == 0 || positions[0] == "" {
				positions = []string{"midsld"}
			}
			first := mapByeDpiPosition(positions[0])
			if method == "hostfakesplit" && positions[0] == "midsld" {
				first = "0+hm"
			}
			out = append(out, "--fake", first)
			for _, position := range positions[1:] {
				out = append(out, "--split", mapByeDpiPosition(position))
			}
		case "fakeddisorder":
			if len(positions) == 0 {
				positions = []string{"midsld"}
			}
			out = append(out, "--fake", mapByeDpiPosition(positions[0]))
			for _, position := range positions[1:] {
				out = append(out, "--disorder", mapByeDpiPosition(position))
			}
		case "multidisorder":
			for _, position := range positions {
				out = append(out, "--disorder", mapByeDpiPosition(position))
			}
		}
	}
	return out
}

func nativeFakeBlob(value string) bool {
	return value == "fake_default_tls" || value == "public_tls_pattern" || hexBlobArgument(value) != ""
}

func validNativeTTL(value string) string {
	value = strings.TrimSpace(value)
	n, err := strconv.Atoi(value)
	if err != nil || n < 1 || n > 255 {
		return ""
	}
	return strconv.Itoa(n)
}

func tlsModSNI(value string) string {
	value = strings.TrimSpace(value)
	if strings.HasPrefix(value, "sni=") {
		host := strings.TrimSpace(strings.TrimPrefix(value, "sni="))
		if host != "" && !strings.ContainsAny(host, " \t\r\n") {
			return host
		}
	}
	return ""
}

// ByeDPI accepts a C-style escaped data string. Restrict this conversion to
// short, even-length hexadecimal blobs so arbitrary file references are never
// treated as local paths on Android.
func hexBlobArgument(value string) string {
	value = strings.TrimSpace(value)
	if !strings.HasPrefix(value, "0x") {
		return ""
	}
	hex := value[2:]
	if len(hex) == 0 || len(hex)%2 != 0 || len(hex) > 512 {
		return ""
	}
	var escaped strings.Builder
	escaped.WriteByte(':')
	for i := 0; i < len(hex); i += 2 {
		if _, err := strconv.ParseUint(hex[i:i+2], 16, 8); err != nil {
			return ""
		}
		escaped.WriteString(`\x`)
		escaped.WriteString(strings.ToLower(hex[i : i+2]))
	}
	return escaped.String()
}

func parseZapretDesync(spec string) (string, map[string]string, bool) {
	parts := strings.Split(spec, ":")
	if len(parts) == 0 || parts[0] == "" {
		return "", nil, false
	}
	fields := make(map[string]string)
	for _, part := range parts[1:] {
		if index := strings.IndexByte(part, '='); index > 0 {
			fields[part[:index]] = part[index+1:]
		}
	}
	return parts[0], fields, true
}

func splitZapretPositions(value string) []string {
	if value == "" {
		return nil
	}
	parts := strings.Split(value, ",")
	out := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part != "" {
			out = append(out, part)
		}
	}
	return out
}

func mapByeDpiPosition(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	switch value {
	case "midsld":
		return "0+sm"
	case "midsld-2":
		return "-2+sm"
	case "midsld+2":
		return "2+sm"
	case "sniext+1", "host+1":
		if value == "host+1" {
			return "1+h"
		}
		return "1+s"
	case "sniext+4":
		return "4+s"
	case "endhost-1":
		return "-1+he"
	default:
		if _, err := strconv.Atoi(value); err == nil {
			return value
		}
		return "0+sm"
	}
}

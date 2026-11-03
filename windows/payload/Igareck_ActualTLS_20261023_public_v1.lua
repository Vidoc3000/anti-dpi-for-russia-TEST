-- Compatibility guard for the pinned bol-van Windows Bundle.
-- Only fake:blob=reasm_data:tls_mod=... is affected. Valid actual ClientHello
-- data is passed through byte-for-byte; unusable fake templates use the stock
-- TLS template. The real packet, destination, SNI and split handler are untouched.

local function be16(s, p)
    local a, b = string.byte(s, p, p + 1)
    if not b then return nil end
    return a * 256 + b
end

local function actual_tls_template_usable(s)
    if type(s) ~= "string" or #s < 44 then return false, "short" end
    local content_type, major, minor = string.byte(s, 1, 3)
    if content_type ~= 22 or major ~= 3 or minor > 3 then
        return false, "not_tls_record"
    end
    local record_end = 5 + be16(s, 4)
    if record_end > #s or record_end < 44 then return false, "incomplete_record" end
    if string.byte(s, 6) ~= 1 or string.byte(s, 10) ~= 3 or string.byte(s, 11) > 3 then
        return false, "not_client_hello"
    end
    local a, b, c = string.byte(s, 7, 9)
    local hello_end = 9 + a * 65536 + b * 256 + c
    if hello_end > record_end or hello_end < 44 then return false, "incomplete_hello" end
    local session_len = string.byte(s, 44)
    if session_len > 32 then return false, "session_id" end
    local p = 45 + session_len
    if p + 1 > hello_end then return false, "cipher_length" end
    local cipher_len = be16(s, p)
    if cipher_len < 2 or cipher_len % 2 ~= 0 then return false, "cipher_suites" end
    p = p + 2 + cipher_len
    if p > hello_end then return false, "compression_length" end
    local compression_len = string.byte(s, p)
    if compression_len < 1 then return false, "compression_methods" end
    p = p + 1 + compression_len
    if p + 1 > hello_end then return false, "no_extensions" end
    local extensions_end = p + 1 + be16(s, p)
    if extensions_end ~= hello_end then return false, "extension_length" end
    p = p + 2
    local has_sni = false
    while p <= extensions_end do
        if p + 3 > extensions_end then return false, "extension_header" end
        local extension_type, extension_len = be16(s, p), be16(s, p + 2)
        local first, last = p + 4, p + 3 + extension_len
        if last > extensions_end then return false, "extension_data" end
        if extension_type == 0 then
            -- The native SNI modifier needs a complete, nonempty first host_name.
            if has_sni or extension_len < 6 or be16(s, first) ~= extension_len - 2 then
                return false, "sni_list"
            end
            if string.byte(s, first + 2) ~= 0 then return false, "sni_name_type" end
            local hostname_len = be16(s, first + 3)
            if hostname_len < 1 or hostname_len + 5 > extension_len then
                return false, "sni_hostname"
            end
            has_sni = true
        end
        p = last + 1
    end
    if not has_sni then return false, "no_sni" end
    return true
end

igareck_actual_tls_template_usable = actual_tls_template_usable

if not igareck_actual_tls_guard_v9 then
    assert(type(fake) == "function", "Igareck ActualTLS: missing stock fake")
    assert(type(fake_default_tls) == "string", "Igareck ActualTLS: missing stock TLS template")
    assert(actual_tls_template_usable(fake_default_tls), "Igareck ActualTLS: stock TLS template is unusable")
    local stock_fake = fake
    function fake(ctx, desync)
        local arg = desync.arg
        if arg.blob == "reasm_data" and arg.tls_mod and desync.reasm_data
            and (desync.dis.tcp or desync.dis.udp) and direction_check(desync)
            and payload_check(desync) and replay_first(desync) then
            local usable, reason = actual_tls_template_usable(desync.reasm_data)
            if not usable then
                -- Copy the argument table, never alter the original TLS payload.
                local fallback_arg = {}
                for k, v in pairs(arg) do fallback_arg[k] = v end
                fallback_arg.blob = "fake_default_tls"
                if b_debug then DLOG("Igareck ActualTLS: stock fake fallback: " .. reason) end
                desync.arg = fallback_arg
                local ok, verdict = pcall(stock_fake, ctx, desync)
                desync.arg = arg
                if not ok then error(verdict, 0) end
                return verdict
            end
        end
        return stock_fake(ctx, desync)
    end
    igareck_actual_tls_guard_v9 = true
end

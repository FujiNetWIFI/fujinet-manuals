-- text.lua -- what is on the cartridge's text planes, decoded through the
-- font, and does it match what the reply said? Compares RENDERED FORMS: the
-- expected string is rendered to glyph keys with the same font table, so a
-- '5' and an 'S' (identical at 3x5) can never make a false failure.
--   TEXT_ROWS="18:0 19:140 20:125"  row:reply-offset pairs to check
package.path = (os.getenv("A2600_EMU") or ".") .. "/?.lua;" .. package.path
local font = require("vcsfont")
local sp = manager.machine.devices[":maincpu"].spaces["program"]
local waited, done = 0, false
local spec = os.getenv("TEXT_ROWS") or "18:0 19:140 20:125"
-- TEXT_WANT="18:HELLO WORLD|19:SECOND ROW" compares against literal text instead
local want_lit = os.getenv("TEXT_WANT")
local function rowkeys(row)
    local keys = {}
    for col = 0, 11 do
        local plane = 0x1800 + (col // 2) * 0x80
        local key = 0
        for line = 0, 4 do
            local b = sp:readv_u8(plane + row * 6 + line)
            local ink = (col % 2 == 0) and ((b >> 5) & 7) or ((b >> 1) & 7)
            key = key * 8 + ink
        end
        keys[#keys + 1] = key
    end
    return keys
end
local function wantkeys(off)
    local keys = {}
    for i = 0, 11 do
        local c = sp:readv_u8(0x1B00 + off + i)
        if c == 0 then break end
        local ch = string.char(c):upper()
        keys[#keys + 1] = font.key[ch] or font.key["?"]
    end
    while #keys < 12 do keys[#keys + 1] = font.key[" "] end
    return keys
end
local function litkeys(txt)
    local keys = {}
    for i = 1, #txt do
        local ch = txt:sub(i, i):upper()
        keys[#keys + 1] = font.key[ch] or font.key["?"]
    end
    while #keys < 12 do keys[#keys + 1] = font.key[" "] end
    return keys
end
local function decode(keys)
    local s = ""
    for _, k in ipairs(keys) do s = s .. (font.glyph[k] or "#") end
    return s
end
_G._text = emu.add_machine_frame_notifier(function()
    if done then return end
    local ack = sp:readv_u8(0x1F00)
    if sp:readv_u8(0x1F09) ~= 0x46 or (ack == 0 and not want_lit) then
        waited = waited + 1
        if waited > 900 then print("FAIL: no transaction"); done = true; manager.machine:exit() end
        return
    end
    waited = waited + 1
    if waited < (want_lit and 240 or 60) then return end   -- let the rows land
    done = true
    local ok = true
    local checks = {}
    if want_lit then
        for pair in want_lit:gmatch("[^|]+") do
            local row, txt = pair:match("^(%d+):(.*)$")
            checks[#checks + 1] = { tonumber(row), litkeys(txt) }
        end
    else
        for pair in spec:gmatch("%S+") do
            local row, off = pair:match("(%d+):(%d+)")
            checks[#checks + 1] = { tonumber(row), wantkeys(tonumber(off)) }
        end
    end
    for _, c in ipairs(checks) do
        local row, want = c[1], c[2]
        local got = rowkeys(row)
        local same = true
        for i = 1, 12 do if got[i] ~= want[i] then same = false end end
        print(string.format("TEXT row %2d %-12s %s", row, decode(got),
                            same and "ok" or ("MISMATCH want " .. decode(want))))
        ok = ok and same
    end
    print(string.format("TEXT err=%d rxlen=%d", sp:readv_u8(0x1F02),
                        sp:readv_u8(0x1F04) + 256 * sp:readv_u8(0x1F05)))
    print(ok and "PASS" or "FAIL")
    manager.machine:exit()
end)

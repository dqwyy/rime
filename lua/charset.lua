--[[
charset_filter: 滤除非白名单内的汉字，且拒绝所有兼容区汉字
白名单由 gb2312.txt 和 user_han.txt（可选）合并而成
该编自 https://github.com/riverscn/rime-forge/blob/main/lua/charset.lua
]]

local allowed_han = {}
do
    local appdata = os.getenv("APPDATA")
    local base_path = appdata .. "\\Rime\\lua\\"

    -- 加载主字表 gb2312.txt
    local file = io.open(base_path .. "gb2312.txt", "r")
    if file then
        for line in file:lines() do
            line = line:match("^%s*(.-)%s*$")
            if line and utf8.len(line) == 1 then
                local cp = utf8.codepoint(line)
                if cp then
                    allowed_han[cp] = true
                end
            end
        end
        file:close()
    end

    -- 加载用户自定义字表 user_han.txt（可选）
    local user_file = io.open(base_path .. "user_han.txt", "r")
    if user_file then
        for line in user_file:lines() do
            line = line:match("^%s*(.-)%s*$")
            if line and utf8.len(line) == 1 then
                local cp = utf8.codepoint(line)
                if cp then
                    allowed_han[cp] = true
                end
            end
        end
        user_file:close()
    end
end

-- 判断是否为普通 CJK 汉字（不含兼容区）
local function is_cjk_char(c)
    return (c >= 0x4E00 and c <= 0x9FFF) or
           (c >= 0x3400 and c <= 0x4DBF) or
           (c >= 0x20000 and c <= 0x2A6DF) or
           (c >= 0x2A700 and c <= 0x2B73F) or
           (c >= 0x2B740 and c <= 0x2B81F) or
           (c >= 0x2B820 and c <= 0x2CEAF) or
           (c >= 0x2CEB0 and c <= 0x2EBEF) or
           (c >= 0x30000 and c <= 0x3134F)
end

-- 判断是否为 CJK 兼容汉字（两个区：U+F900-FAFF 和 U+2F800-2FA1F）
local function is_compat_han(c)
    return (c >= 0xF900 and c <= 0xFAFF) or
           (c >= 0x2F800 and c <= 0x2FA1F)
end

local function charset_filter(input, env)
    local b_extended = env.engine.context:get_option("extended_charset")

    for cand in input:iter() do
        if b_extended then
            yield(cand)
        else
            local valid = true
            for _, cp in utf8.codes(cand.text) do
                -- 兼容区汉字一律拒绝
                if is_compat_han(cp) then
                    valid = false
                    break
                end
                -- 普通汉字：不在白名单则拒绝
                if is_cjk_char(cp) and not allowed_han[cp] then
                    valid = false
                    break
                end
                -- 非汉字字符忽略，继续检查
            end
            if valid then
                yield(cand)
            end
        end
    end
end

return { filter = charset_filter }
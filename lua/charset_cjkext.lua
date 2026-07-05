-- 自定义增补字，总是保留
local extra = {
    0x30EDE, -- 𰻞 biang
}

-- CJK 统一表意文字各区块范围
local charset = {
    ["CJK"]        = { first = 0x4E00,  last = 0x9FFF },
    ["ExtA"]       = { first = 0x3400,  last = 0x4DBF },
    ["ExtB"]       = { first = 0x20000, last = 0x2A6DF },
    ["ExtC"]       = { first = 0x2A700, last = 0x2B73F },
    ["ExtD"]       = { first = 0x2B740, last = 0x2B81F },
    ["ExtE"]       = { first = 0x2B820, last = 0x2CEAF },
    ["ExtF"]       = { first = 0x2CEB0, last = 0x2EBEF },
    ["Compat"]     = { first = 0x2F800, last = 0x2FA1F },   -- 兼容补充
    ["CompatIdeo"] = { first = 0xF900,  last = 0xFAFF },   -- 兼容主区
    ["ExtG"]       = { first = 0x30000, last = 0x3134F },
    ["ExtH"]       = { first = 0x31350, last = 0x323AF },
    ["ExtI"]       = { first = 0x2EBF0, last = 0x2EE5F },
}

-- 检查整个字符串是否全部满足 single_filter 条件
local function exists(single_filter, text)
    for i in utf8.codes(text) do
        local c = utf8.codepoint(text, i)
        if not single_filter(c) then
            return false
        end
    end
    return true
end

-- 返回判断 codepoint 是否属于指定字符集的函数
local function is_charset(s)
    return function(c)
        return c >= charset[s].first and c <= charset[s].last
    end
end

-- 判断是否为扩展汉字（包括所有非基本区）
local function is_cjk_ext(c)
    return is_charset("ExtA")(c)
        or is_charset("ExtB")(c)
        or is_charset("ExtC")(c)
        or is_charset("ExtD")(c)
        or is_charset("ExtE")(c)
        or is_charset("ExtF")(c)
        or is_charset("Compat")(c)
        or is_charset("CompatIdeo")(c)
        or is_charset("ExtG")(c)
        or is_charset("ExtH")(c)
        or is_charset("ExtI")(c)
end

-- 检查是否属于自定义增补字
local function is_extra(c)
    for _, v in pairs(extra) do
        if v == c then
            return true
        end
    end
    return false
end

-- 主过滤器
local function charset_filter(input, env)
    local b_extended_charset = env.engine.context:get_option("extended_charset")

    for cand in input:iter() do
        -- 保留条件：
        -- 1. 已开启扩展字符集选项
        -- 2. 或候选不含任何 CJK 扩展/兼容区汉字
        -- 3. 或候选属于自定义增补字列表
        if b_extended_charset
            or not exists(is_cjk_ext, cand.text)
            or exists(is_extra, cand.text) then
            yield(cand)
        end
    end
end

return {
    filter = charset_filter
}
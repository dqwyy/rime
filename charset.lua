--[[
关于CJK扩展字符
  CJK = 中日韩（China, Japan, Korea），这个主要是指的东亚地区使用汉字及部分衍生偏僻字的字符集
  （由于其使用频率非常低，一般的电脑系统里没有相关的字符，因此不能显示这些字）

查询unicode 编码
  1. https://unicode.org/charts/

导出函数
  1. charset_filter: 滤除含 CJK 扩展汉字的候选项
  2. charset_comment_filter: 为候选项加上其所属字符集的注释

本例说明了 filter 最基本的写法。

请见 `charset_filter` 和 `charset_comment_filter` 上方注释。
--]]

-- 帮助函数（可跳过）
local charset = {
   ["CJK"] = { first = 0x4E00, last = 0x9FFF },         -- CJK Unified Ideographs - https://unicode.org/charts/PDF/U4E00.pdf
--   ["ExtA"] = { first = 0x3400, last = 0x4DBF },        -- CJK Unified Ideographs Extension A - https://unicode.org/charts/PDF/U3400.pdf
--   ["ExtB"] = { first = 0x20000, last = 0x2A6DF },      -- CJK Unified Ideographs Extension B - https://unicode.org/charts/PDF/U20000.pdf
--   ["ExtC"] = { first = 0x2A700, last = 0x2B73F },      -- CJK Unified Ideographs Extension C - https://unicode.org/charts/PDF/U2A700.pdf
--   ["ExtD"] = { first = 0x2B740, last = 0x2B81F },      -- CJK Unified Ideographs Extension D - https://unicode.org/charts/PDF/U2B740.pdf
--   ["ExtE"] = { first = 0x2B820, last = 0x2CEAF },      -- CJK Unified Ideographs Extension E - https://unicode.org/charts/PDF/U2B820.pdf
--   ["ExtF"] = { first = 0x2CEB0, last = 0x2EBEF },      -- CJK Unified Ideographs Extension F - https://unicode.org/charts/PDF/U2CEB0.pdf
--   ["ExtG"] = { first = 0x30000, last = 0x3134A },      -- CJK Unified Ideographs Extension G - https://unicode.org/charts/PDF/U30000.pdf
   ["Compat"] = { first = 0xF900, last = 0xFAFF },      -- CJK Compatibility Ideographs - https://unicode.org/charts/PDF/UF900.pdf
   ["CompatSupp"] = { first = 0x2F800, last = 0x2FA1F }, -- CJK Compatibility Ideographs Supplement - https://unicode.org/charts/PDF/U2F800.pdf
   ["ext1"]={first=0x3400,last=0x340D},["ext2"]={first=0x340F,last=0x4DBF},  --保留ExtA中的U+340E㐎
   ["ext3"]={first=0x20000,last=0x2003D},
   --保留U+2003E𠀾
   ["ext4"]={first=0x2003F,last=0x24C08},
   --保留U+24C09𤰉
   ["ext5"]={first=0x24C0A,last=0x323AF}

}

local function exists(single_filter, text)
  for i in utf8.codes(text) do
     local c = utf8.codepoint(text, i)
     if (not single_filter(c)) then
	return false
     end
  end
  return true
end

local function is_charset(s)
   return function (c)
      return c >= charset[s].first and c <= charset[s].last
   end
end

local function is_cjk_ext(c)
   return is_charset("ext1")(c) or
      is_charset("ext2")(c) or
      is_charset("ext3")(c) or
      is_charset("ext4")(c) or
      is_charset("ext5")(c) or
      is_charset("Compat")(c) or
      is_charset("CompatSupp")(c)
end

--[[
filter 的功能是对 translator 翻译而来的候选项做修饰，
如去除不想要的候选、为候选加注释、候选项重排序等。

欲定义的 filter 包含两个输入参数：
 - input: 候选项列表
 - env: 可选参数，表示 filter 所处的环境（本例没有体现）

filter 的输出与 translator 相同，也是若干候选项，也要求您使用 `yield` 产生候选项。

如下例所示，charset_filter 将滤除含 CJK 扩展汉字的候选项：
--]]
local function charset_filter(input)
   -- 使用 `iter()` 遍历所有输入候选项
   for cand in input:iter() do
      -- 如果当前候选项 `cand` 不含 CJK 扩展汉字
      if (not exists(is_cjk_ext, cand.text))
      then
	 -- 结果中仍保留此候选
	 yield(cand)
      end
      --[[ 上述条件不满足时，当前的候选 `cand` 没有被 yield。
           因此过滤结果中将不含有该候选。
      --]]
   end
end

-- 本例中定义了两个 filter，故使用一个表将两者导出
return { filter = charset_filter }
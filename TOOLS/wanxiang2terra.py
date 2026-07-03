import sys

# 带声调字母到 (基础字母, 声调数字) 的映射
TONE_MAP = {
    'ā': ('a', 1), 'á': ('a', 2), 'ǎ': ('a', 3), 'à': ('a', 4),
    'ē': ('e', 1), 'é': ('e', 2), 'ě': ('e', 3), 'è': ('e', 4),
    'ī': ('i', 1), 'í': ('i', 2), 'ǐ': ('i', 3), 'ì': ('i', 4),
    'ō': ('o', 1), 'ó': ('o', 2), 'ǒ': ('o', 3), 'ò': ('o', 4),
    'ū': ('u', 1), 'ú': ('u', 2), 'ǔ': ('u', 3), 'ù': ('u', 4),
    'ǖ': ('v', 1), 'ǘ': ('v', 2), 'ǚ': ('v', 3), 'ǜ': ('v', 4),
}


def convert_syllable(syl):
    """
    转换单个拼音音节。
    例如: 'mā' -> 'ma1', 'ma' -> 'ma5', 'nǚ' -> 'nv3', 'lüè' -> 'lve4'
    """
    tone = 5  # 默认轻声
    out_chars = []
    for ch in syl:
        if ch in TONE_MAP:
            base, t = TONE_MAP[ch]
            out_chars.append(base)
            tone = t  # 一个音节只有一个声调，直接覆盖
        elif ch == 'ü':
            out_chars.append('v')
            # 无声调的 ü，保持 tone = 5（除非后续还有带调字符）
        else:
            out_chars.append(ch)
    return ''.join(out_chars) + str(tone)


def convert_pinyin(pinyin_str):
    """
    转换整个拼音字段（可能包含多个音节，空格分隔）。
    例如: 'wǒ men' -> 'wo3 men5'
    """
    syllables = pinyin_str.strip().split()
    converted = [convert_syllable(s) for s in syllables]
    return ' '.join(converted)


def process_file(input_path, output_path, delimiter='\t'):
    """
    逐行处理词库文件，将拼音字段转换后写入新文件。
    默认行格式: 词语<tab>拼音<tab>词频
    """
    with open(input_path, 'r', encoding='utf-8') as fin, \
         open(output_path, 'w', encoding='utf-8') as fout:
        for line in fin:
            line = line.rstrip('\n')
            if not line:
                continue
            parts = line.split(delimiter)
            if len(parts) == 3:
                word, pinyin, freq = parts
                new_pinyin = convert_pinyin(pinyin)
                fout.write(f"{word}{delimiter}{new_pinyin}{delimiter}{freq}\n")
            else:
                # 如果格式不符合预期，可选择原样保留或报错
                print(f"Warning: line format unexpected, skipped: {line[:50]}...", file=sys.stderr)
                fout.write(line + '\n')


if __name__ == '__main__':
    # 使用示例：将 input.txt 转换为 output.txt
    input_file = 'jichu.dict.yaml'
    output_file = 'output.yaml'
    process_file(input_file, output_file)
    print("转换完成！")
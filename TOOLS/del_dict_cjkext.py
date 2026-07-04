#!/usr/bin/env python3
"""
过滤 Rime 词库，保留 CJK 基本区汉字条目，并额外保留 user_han.txt 中指定的字符。
例外字符列表从 %APPDATA%/Rime/lua/user_han.txt 加载（一行一个汉字）。
用法：python filter_cjk_basic.py 输入文件 输出文件
"""

import sys
import os

# 内置默认例外集合（当 user_han.txt 不存在时使用）
DEFAULT_EXCEPTIONS = {
    '〇',

}

def load_exceptions_from_file():
    """从 %APPDATA%/Rime/lua/user_han.txt 加载例外字符集合。
    如果文件存在且可读，则使用文件内容；否则回退到内置默认集合并给出警告。
    """
    # 展开 %APPDATA% 并构建路径（使用正斜杠避免转义问题）
    appdata = os.environ.get('APPDATA', '')
    if not appdata:
        print("警告: 无法获取 APPDATA 环境变量，使用当前目录下的 user_han.txt")
        file_path = 'user_han.txt'
    else:
        file_path = os.path.join(appdata, 'Rime', 'lua', 'user_han.txt')

    if not os.path.isfile(file_path):
        print(f"警告: 未找到例外字符文件 '{file_path}'，将使用内置默认例外集合。")
        print(f"       你可以创建该文件（每行一个汉字）来定制例外字符列表。")
        return DEFAULT_EXCEPTIONS

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            chars = set()
            for line in f:
                line = line.strip()
                if line:
                    chars.add(line[0])   # 只取第一个字符（防止行内有杂物）
            if not chars:
                print(f"警告: 文件 '{file_path}' 为空，将使用内置默认例外集合。")
                return DEFAULT_EXCEPTIONS
            return chars
    except Exception as e:
        print(f"错误: 读取文件 '{file_path}' 失败: {e}，将使用内置默认例外集合。")
        return DEFAULT_EXCEPTIONS

def is_cjk_basic(char: str) -> bool:
    """判断单个字符是否属于 CJK 统一表意文字基本区块"""
    if len(char) != 1:
        return False
    cp = ord(char)
    return 0x4E00 <= cp <= 0x9FFF

def should_keep(char: str, exceptions: set) -> bool:
    """判断该汉字是否应该保留（基本区或例外列表）"""
    return is_cjk_basic(char) or char in exceptions

def process_line(line: str, exceptions: set) -> str | None:
    """如果该行第一个非空字符是应保留的汉字，返回原行（去掉尾部换行），否则返回 None"""
    stripped_line = line.rstrip('\n\r')
    if not stripped_line:
        return None
    lstrip_line = stripped_line.lstrip()
    if not lstrip_line:
        return None
    first_char = lstrip_line[0]
    if should_keep(first_char, exceptions):
        return stripped_line
    return None

def main():
    if len(sys.argv) != 3:
        print(f"用法: {sys.argv[0]} 输入文件 输出文件")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    exceptions = load_exceptions_from_file()
    print(f"已加载 {len(exceptions)} 个例外字符。")

    kept = 0
    deleted = 0
    blank = 0

    with open(input_path, 'r', encoding='utf-8-sig') as fin, \
         open(output_path, 'w', encoding='utf-8') as fout:
        for line in fin:
            processed = process_line(line, exceptions)
            if processed is not None:
                fout.write(processed + '\n')
                kept += 1
            else:
                if line.strip() == '':
                    blank += 1
                else:
                    deleted += 1

    print(f"处理完成，结果保存在: {output_path}")
    print(f"保留: {kept} 行")
    print(f"删除: {deleted} 行")
    print(f"空行: {blank} 行（已跳过）")

if __name__ == '__main__':
    main()
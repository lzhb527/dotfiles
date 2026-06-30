#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：fix_icons_flat.py
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-15 19:07:40
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
import os
import re
from pypinyin import pinyin, Style

# 🎯 1. 升级：同时扫描原生系统路径与所有可能的 Flatpak 路径
SCAN_DIRS = [
    "/usr/share/applications",  # 系统原生应用
    "/var/lib/flatpak/exports/share/applications",  # Flatpak 全局应用
    os.path.expanduser(
        "~/.local/share/flatpak/exports/share/applications")  # Flatpak 用户应用
]

USER_DIR = os.path.expanduser("~/.local/share/applications")
os.makedirs(USER_DIR, exist_ok=True)

# 🎯 2. 手动静态映射（防止某些纯英文应用你想强制加中文，可随时追加）
MANUAL_MAP = {
    "brave-browser.desktop": "Brave 浏览器",
    "com.brave.Browser.desktop": "Brave 浏览器",
    "firefox-esr.desktop": "Firefox 火狐浏览器",
    "kitty.desktop": "Kitty 终端",
    "Alacritty.desktop": "Alacritty 终端",
    "foot.desktop": "Foot 终端",
    "footclient.desktop": "Foot 终端客户端",
    "org.nickvision.tubeconverter.desktop": "Parabolic 视频音频下载器 Tube Converter",
}


def get_pinyin_keywords(text):
    if not text: return []
    chinese_chars = "".join(re.findall(r"[\u4e00-\u9fa5]", text))
    if not chinese_chars: return []

    full_pinyin_list = pinyin(chinese_chars, style=Style.NORMAL)
    full_pinyin = "".join(
        [sublist[0] for sublist in full_pinyin_list if sublist])

    first_letter_list = pinyin(chinese_chars, style=Style.FIRST_LETTER)
    first_letter = "".join(
        [sublist[0] for sublist in first_letter_list if sublist])

    return [full_pinyin, first_letter]


def process_file(src_dir, filename):
    src_path = os.path.join(src_dir, filename)
    dest_path = os.path.join(USER_DIR, filename)

    with open(src_path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

    # 搜集所有可能的中文信息
    chinese_hints = []
    if filename in MANUAL_MAP:
        chinese_hints.append(MANUAL_MAP[filename])

    is_main_entry = False
    for line in lines:
        cleaned = line.strip()
        if cleaned == "[Desktop Entry]":
            is_main_entry = True
        elif cleaned.startswith("[") and cleaned.endswith("]"):
            is_main_entry = False

        if is_main_entry:
            if line.startswith("Name[zh_CN]=") or line.startswith(
                    "GenericName[zh_CN]=") or line.startswith(
                        "Keywords[zh_CN]="):
                val = line.split("=", 1)[1].strip()
                chinese_hints.append(val)
            elif line.startswith("Name="):
                val = line.split("=", 1)[1].strip()
                if re.search(r"[\u4e00-\u9fa5]", val):
                    chinese_hints.append(val)

    combined_chinese = " ".join(chinese_hints)
    found_chinese_words = re.findall(r"[\u4e00-\u9fa5]+", combined_chinese)

    if not found_chinese_words:
        return False

    pinyin_tags = []
    for word in found_chinese_words:
        pinyin_tags.extend(get_pinyin_keywords(word))
    pinyin_tags = list(set(pinyin_tags))

    output_lines = []
    in_desktop_entry = False
    keywords_injected = False

    for line in lines:
        cleaned = line.strip()
        if cleaned == "[Desktop Entry]":
            in_desktop_entry = True
            output_lines.append(line)
            continue
        elif cleaned.startswith("[") and cleaned.endswith("]"):
            if in_desktop_entry and not keywords_injected:
                new_kw_str = ";".join(pinyin_tags + found_chinese_words) + ";"
                output_lines.append(f"Keywords={new_kw_str}\n")
                keywords_injected = True
            in_desktop_entry = False

        if in_desktop_entry and line.startswith("Keywords="):
            orig_kw = line.replace("Keywords=", "").strip().split(";")
            merged_kw = list(set(orig_kw + pinyin_tags + found_chinese_words))
            merged_kw_str = ";".join([k for k in merged_kw if k]) + ";"
            output_lines.append(f"Keywords={merged_kw_str}\n")
            keywords_injected = True
        else:
            output_lines.append(line)

    if in_desktop_entry and not keywords_injected:
        new_kw_str = ";".join(pinyin_tags + found_chinese_words) + ";"
        output_lines.append(f"Keywords={new_kw_str}\n")

    with open(dest_path, "w", encoding="utf-8") as f:
        f.writelines(output_lines)

    print(
        f"🔥 完美适配: {filename} -> 提取到中文: {list(set(found_chinese_words))} 拼音标签: {pinyin_tags}"
    )
    return True


# 🎯 3. 升级：循环遍历所有配置的目录
success_count = 0
for d in SCAN_DIRS:
    if os.path.exists(d):
        for item in os.listdir(d):
            if item.endswith(".desktop"):
                if process_file(d, item):
                    success_count += 1

print(f"\n🚀 处理完成！已为 {success_count} 个应用（含 Flatpak）无损注入了中英双语与全拼音关键词。")

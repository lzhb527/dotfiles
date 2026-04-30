#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：smpc.py
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-04-17 13:19:57
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.


import sys
import os
from mpd import MPDClient, ConnectionError

class MPDControl:
    def __init__(self, host="localhost", port=6600):
        self.client = MPDClient()
        try:
            self.client.connect(host, port)
        except Exception as e:
            print(f"❌ 无法连接到 MPD 服务: {e}")
            sys.exit(1)

    def get_status_str(self):
        """获取当前播放状态简报"""
        status = self.client.status()
        song = self.client.currentsong()
        state = status.get('state', 'Unknown').upper()
        title = song.get('title', song.get('file', '停止'))
        artist = song.get('artist', '未知歌手')
        return f"[{state}] {title} - {artist}"

    def search_and_play(self):
        """模糊搜索当前播放列表并播放"""
        # 1. 获取当前播放队列
        playlist = self.client.playlistinfo()
        if not playlist:
            print("❗ 当前播放列表为空")
            return

        keyword = input("\n🔍 输入搜索关键词 (支持中英文模糊匹配): ").strip().lower()
        
        # 2. 过滤匹配项
        results = []
        for song in playlist:
            title = song.get('title', '').lower()
            file = song.get('file', '').lower()
            artist = song.get('artist', '').lower()
            
            if keyword in title or keyword in file or keyword in artist:
                results.append(song)

        # 3. 显示结果并选择
        if not results:
            print("❌ 未找到匹配歌曲")
            return

        print(f"\n--- 找到 {len(results)} 首匹配歌曲 ---")
        for i, s in enumerate(results):
            print(f"[{i}] {s.get('title', s.get('file'))}")

        choice = input("\n请输入编号播放 (回车取消): ")
        if choice.isdigit():
            idx = int(choice)
            if 0 <= idx < len(results):
                # 获取该歌曲在原始队列中的位置 ID (Id) 或位置 (Pos)
                song_pos = results[idx].get('pos')
                self.client.play(song_pos)
                print(f"▶️ 即将播放: {results[idx].get('title')}")

    def show_menu(self):
        os.system('clear')
        print("="*40)
        print(f"  {self.get_status_str()}")
        print("="*40)
        print(" [P] 播放/暂停  [N] 下一首  [B] 上一首")
        print(" [L] 播放列表  [F] 模糊搜索  [Q] 退出")
        print("-" * 40)

    def run(self):
        while True:
            try:
                self.show_menu()
                cmd = input("指令 > ").lower().strip()

                if cmd == 'p':
                    status = self.client.status()
                    self.client.pause(1) if status['state'] == 'play' else self.client.play()
                elif cmd == 'n':
                    self.client.next()
                elif cmd == 'b':
                    self.client.previous()
                elif cmd == 'l':
                    playlist = self.client.playlistinfo()
                    print("\n--- 当前播放列表 ---")
                    for s in playlist[:20]: # 仅列出前20首防止刷屏
                        print(f" - {s.get('title', s.get('file'))}")
                    input("\n按回车继续...")
                elif cmd == 'f':
                    self.search_and_play()
                    input("\n按回车继续...")
                elif cmd == 'q':
                    self.client.disconnect()
                    break
            except (ConnectionError, Exception) as e:
                print(f"发生错误: {e}")
                input("按回车尝试重连...")
                try: self.client.connect("localhost", 6600)
                except: pass

if __name__ == "__main__":
    MPDControl().run()


#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：mpd-client-fixed.py
# Description：基于 mpc readpicture 精准渲染封面的悬浮音乐客户端

import os
import re
import subprocess
import threading
import time

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk

# 临时存放封面图片的路径
ALBUM_ART_TMP = "/tmp/mpd_working_cover.jpg"


class MPDClientCenter(Gtk.Window):
    def __init__(self):
        super().__init__(title="MPD Control Center")

        # 1. 窗口基础设置：无边框悬浮面板
        self.set_decorated(False)
        self.set_default_size(420, 240)
        self.set_keep_above(True)
        self.set_position(Gtk.WindowPosition.CENTER)

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and self.is_composited():
            self.set_visual(visual)

        # 2. 界面核心布局（横向大盒子）
        main_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        main_hbox.set_margin_top(20)
        main_hbox.set_margin_bottom(20)
        main_hbox.set_margin_start(20)
        main_hbox.set_margin_end(20)
        self.add(main_hbox)

        # ---- 左侧：专辑封面图片容器 ----
        self.cover_image = Gtk.Image()
        self.set_default_cover()
        main_hbox.pack_start(self.cover_image, False, False, 0)

        # ---- 右侧：控制与信息垂直盒子 ----
        right_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        main_hbox.pack_start(right_vbox, True, True, 0)

        # 歌曲标题
        self.title_label = Gtk.Label(label="🎶 未在播放")
        self.title_label.set_halign(Gtk.Align.START)
        self.title_label.set_line_wrap(True)
        self.title_label.set_max_width_chars(22)
        right_vbox.pack_start(self.title_label, False, False, 0)

        # 播放状态与时间进度
        self.status_label = Gtk.Label(label="[停止] 0:00 / 0:00")
        self.status_label.set_halign(Gtk.Align.START)
        right_vbox.pack_start(self.status_label, False, False, 0)

        # 一行紧凑的纯图标按钮
        btn_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        btn_hbox.set_homogeneous(True)
        right_vbox.pack_start(btn_hbox, False, False, 5)

        prev_btn = Gtk.Button(label="⏮")
        prev_btn.connect("clicked", lambda w: self.run_mpc(["prev"]))
        btn_hbox.pack_start(prev_btn, True, True, 0)

        self.play_btn = Gtk.Button(label="▶")
        self.play_btn.connect("clicked", lambda w: self.run_mpc(["toggle"]))
        btn_hbox.pack_start(self.play_btn, True, True, 0)

        stop_btn = Gtk.Button(label="⏹")
        stop_btn.connect("clicked", lambda w: self.run_mpc(["stop"]))
        btn_hbox.pack_start(stop_btn, True, True, 0)

        next_btn = Gtk.Button(label="⏭")
        next_btn.connect("clicked", lambda w: self.run_mpc(["next"]))
        btn_hbox.pack_start(next_btn, True, True, 0)

        # 进度调节滑动条
        self.progress_scale = Gtk.Scale.new_with_range(
            Gtk.Orientation.HORIZONTAL, 0, 100, 1
        )
        self.progress_scale.set_draw_value(False)
        self.progress_scale.connect("value-changed", self.on_progress_slider_changed)
        right_vbox.pack_start(self.progress_scale, False, False, 0)

        # 3. 快速关闭机制绑定
        self.connect("key-press-event", self.on_key_press)
        self.connect("focus-out-event", lambda w, e: self.close_program())

        # 4. 刷上现代 Nord 暗色皮肤
        self.apply_css()

        # 5. 启动异步状态轮询线程
        self.is_running = True
        self.current_song_file = ""  # 记录当前歌曲的路径作为唯一标识
        threading.Thread(target=self.status_monitor_loop, daemon=True).start()

    def set_default_cover(self):
        """没拿到封面或者停止播放时展示的骨架占位样式"""
        try:
            pixbuf = Gtk.IconTheme.get_default().load_icon(
                "audio-x-generic", 110, Gtk.IconLookupFlags.FORCE_SIZE
            )
            self.cover_image.set_from_pixbuf(pixbuf)
        except Exception:
            self.cover_image.set_from_blank()

    def apply_css(self):
        css = """
        window { background-color: rgba(36, 41, 51, 0.96); border-radius: 16px; border: 1px solid rgba(255, 255, 255, 0.08); }
        label { color: #ECEFF4; font-size: 13px; }
        box > box > label:first-child { font-size: 16px; font-weight: bold; color: #88C0D0; }
        button { background-color: rgba(48, 55, 69, 0.8); color: #E5E9F0; border-radius: 8px; border: 0px; font-size: 15px; padding: 8px 0px; }
        button:hover { background-color: #5E81AC; color: #FFFFFF; }
        image { border-radius: 10px; }
        scale contents trough highlight { background-color: #A3BE8C; border-radius: 4px; }
        scale contents trough { background-color: #4C566A; border-radius: 4px; min-height: 5px; }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def run_mpc(self, args):
        try:
            res = subprocess.run(["mpc"] + args, capture_output=True, text=True)
            return res.stdout.strip()
        except Exception:
            return ""

    def extract_and_load_cover(self, song_file):
        """核心修复逻辑：精确运行你测试成功的底层命令"""
        if not song_file:
            GLib.idle_add(self.set_default_cover)
            return

        try:
            # 1. 严格使用你测试成功的命令：mpc readpicture "歌曲文件相对路径"
            res = subprocess.run(
                ["mpc", "readpicture", song_file], capture_output=True, check=False
            )

            # 2. 如果成功吐出二进制流，将其写入临时文件供 GTK 渲染
            if res.returncode == 0 and len(res.stdout) > 0:
                with open(ALBUM_ART_TMP, "wb") as f:
                    f.write(res.stdout)

                # 3. 推送到主线程由 GdkPixbuf 进行缩放并加载
                GLib.idle_add(self.render_cover_to_ui, ALBUM_ART_TMP)
                return
        except Exception:
            pass

        GLib.idle_add(self.set_default_cover)

    def render_cover_to_ui(self, path):
        try:
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                path, width=110, height=110, preserve_aspect_ratio=True
            )
            self.cover_image.set_from_pixbuf(pixbuf)
        except Exception:
            self.set_default_cover()

    def status_monitor_loop(self):
        while self.is_running:
            title_str = "音乐未在播放"
            status_str = "[停止]"
            progress_pct = 0
            is_playing = False

            output = self.run_mpc([])
            if output:
                lines = output.split("\n")
                if len(lines) >= 2 and (
                    "[playing]" in lines[1] or "[paused]" in lines[1]
                ):
                    title_str = lines[0]
                    status_str = lines[1]
                    is_playing = "[playing]" in lines[1]

                    match_pct = re.search(r"\((\d+)%\)", lines[1])
                    if match_pct:
                        progress_pct = int(match_pct.group(1))

                    # 精准切歌检测：获取当前歌曲对应的实际文件相对路径 %file%
                    current_file = self.run_mpc(["current", "-f", "%file%"])
                    if current_file and current_file != self.current_song_file:
                        self.current_song_file = current_file
                        # 触发后台提取线程
                        threading.Thread(
                            target=self.extract_and_load_cover,
                            args=(current_file,),
                            daemon=True,
                        ).start()
                else:
                    if self.current_song_file != "":
                        self.current_song_file = ""
                        GLib.idle_add(self.set_default_cover)

            GLib.idle_add(
                self.refresh_ui, title_str, status_str, progress_pct, is_playing
            )
            time.sleep(1.0)

    def refresh_ui(self, title_str, status_str, progress_pct, is_playing):
        if not self.is_running:
            return
        self.title_label.set_text(title_str)
        self.status_label.set_text(status_str)
        self.play_btn.set_label("⏸" if is_playing else "▶")

        self.progress_scale.handler_block_by_func(self.on_progress_slider_changed)
        self.progress_scale.set_value(progress_pct)
        self.progress_scale.handler_unblock_by_func(self.on_progress_slider_changed)

    def on_progress_slider_changed(self, slider):
        val = int(slider.get_value())
        threading.Thread(
            target=self.run_mpc, args=(["seek", f"{val}%"],), daemon=True
        ).start()

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_program()

    def close_program(self):
        if self.is_running:
            self.is_running = False
            if os.path.exists(ALBUM_ART_TMP):
                try:
                    os.remove(ALBUM_ART_TMP)
                except Exception:
                    pass
            self.destroy()
            Gtk.main_quit()


if __name__ == "__main__":
    win = MPDClientCenter()
    win.connect("destroy", lambda w: win.close_program())
    win.show_all()
    Gtk.main()

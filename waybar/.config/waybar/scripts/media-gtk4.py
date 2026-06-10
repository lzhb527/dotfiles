#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：1.py
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-31 12:50:39
# Description：完全无边框极简透明版 - 按钮融合优化 + 抽屉式播放列表 (高兼容修复版)

import os
import re
import subprocess
import sys
import threading
import time

import gi

# 环境配置
os.environ["G_MESSAGES_DEBUG"] = ""
os.environ["GSK_RENDERER"] = "cairo"

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk

# 屏蔽 GLib 警告
GLib.log_set_writer_func(lambda *args: GLib.LogWriterOutput.HANDLED, None)

try:
    gi.require_version("Gtk4LayerShell", "1.0")
    from gi.repository import Gtk4LayerShell

    HAS_LAYER_SHELL = True
except (ValueError, ImportError):
    HAS_LAYER_SHELL = False

TARGET_TMP_COVER = "/tmp/mpd_direct_current_cover.jpg"


class MediaControlCenter(Gtk.Window):
    def __init__(self, app):
        super().__init__(title="Media Control Center")
        self.set_application(app)
        self.set_decorated(False)

        self.current_song_file = ""
        self.is_running = True

        if HAS_LAYER_SHELL:
            Gtk4LayerShell.init_for_window(self)
            Gtk4LayerShell.set_layer(self, Gtk4LayerShell.Layer.TOP)
            Gtk4LayerShell.set_keyboard_mode(
                self, Gtk4LayerShell.KeyboardMode.ON_DEMAND
            )
            Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.TOP, True)
            Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.RIGHT, True)
            Gtk4LayerShell.set_margin(self, Gtk4LayerShell.Edge.TOP, 1)
            Gtk4LayerShell.set_margin(self, Gtk4LayerShell.Edge.RIGHT, 380)

        # 根布局容器 (包含播放器主体 + 展开的播放列表)
        root_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        root_vbox.add_css_class("media-panel")
        self.set_child(root_vbox)

        # 播放器主体 (原来的 main_hbox)
        main_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        root_vbox.append(main_hbox)

        # 封面图
        self.cover_image = Gtk.Image()
        self.cover_image.add_css_class("media-cover")
        self.clear_cover()
        main_hbox.append(self.cover_image)

        # 右侧信息与控制区
        right_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        right_vbox.set_valign(Gtk.Align.CENTER)
        main_hbox.append(right_vbox)

        # 1. 歌曲信息
        info_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        right_vbox.append(info_vbox)

        self.title_label = Gtk.Label(label="等待播放...")
        self.title_label.add_css_class("media-title")
        self.title_label.set_halign(Gtk.Align.START)
        self.title_label.set_ellipsize(3)
        self.title_label.set_max_width_chars(18)
        info_vbox.append(self.title_label)

        self.artist_label = Gtk.Label(label="未知艺术家")
        self.artist_label.add_css_class("media-artist")
        self.artist_label.set_halign(Gtk.Align.START)
        info_vbox.append(self.artist_label)

        # 2. 进度条
        self.adj = Gtk.Adjustment(value=0, lower=0, upper=100, step_increment=1)
        self.progress_bar = Gtk.Scale(
            orientation=Gtk.Orientation.HORIZONTAL, adjustment=self.adj
        )
        self.progress_bar.set_draw_value(False)
        self.progress_bar.add_css_class("media-progress")
        self.progress_bar.connect("value-changed", self.on_seek_requested)
        right_vbox.append(self.progress_bar)

        # 3. 极简按钮组
        btn_container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        right_vbox.append(btn_container)

        # 媒体控制行 (Prev, Play, Next)
        ctrl_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        ctrl_hbox.add_css_class("capsule-row")
        btn_container.append(ctrl_hbox)

        for icon, cmd, cls in [
            ("󰒮", ["prev"], "nav-btn"),
            ("󰐊", ["toggle"], "play-btn"),
            ("󰒭", ["next"], "nav-btn"),
        ]:
            btn = Gtk.Button(label=icon)
            btn.add_css_class("icon-btn")
            if cls:
                btn.add_css_class(cls)
            if "play-btn" in cls:
                self.play_btn = btn
            btn.connect("clicked", lambda w, c=cmd: self.run_mpc(c))
            ctrl_hbox.append(btn)

        # 系统控制行 (CLR, SYNC, ALL+, LIST)
        sys_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        sys_hbox.add_css_class("capsule-row")
        btn_container.append(sys_hbox)

        for text, cmd in [
            ("CLR", ["clear"]),
            ("SYNC", ["update"]),
            ("ALL+", ["add", "/"]),
            ("LIST", ["_toggle_list_"]),  # 特殊命令用于触发列表
        ]:
            btn = Gtk.Button(label=text)
            btn.add_css_class("text-btn")
            if cmd == ["_toggle_list_"]:
                btn.connect("clicked", self.toggle_playlist)
            else:
                btn.connect("clicked", lambda w, c=cmd: self.run_mpc(c))
            sys_hbox.append(btn)

        # === 隐藏式播放列表 ===
        self.playlist_revealer = Gtk.Revealer()
        self.playlist_revealer.set_transition_type(
            Gtk.RevealerTransitionType.SLIDE_DOWN
        )
        self.playlist_revealer.set_margin_top(15)
        root_vbox.append(self.playlist_revealer)

        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_min_content_height(100)  # 给定一个最小高度
        scroll.set_max_content_height(250)
        scroll.set_propagate_natural_height(True)  # 让高度根据内容自适应
        self.playlist_revealer.set_child(scroll)

        self.playlist_box = Gtk.ListBox()
        self.playlist_box.add_css_class("playlist-box")
        self.playlist_box.connect("row-activated", self.on_playlist_row_activated)
        scroll.set_child(self.playlist_box)

        # 失去焦点自动隐藏
        focus_controller = Gtk.EventControllerFocus()
        focus_controller.connect("leave", lambda c: self.set_visible(False))
        self.add_controller(focus_controller)

        self.apply_css()
        threading.Thread(target=self.mpd_status_loop, daemon=True).start()

    def apply_css(self):
        css = """
        /* 基础容器：去除阴影和强制背景透明 */
        window { background: transparent; }
        
        .media-panel { 
            background-color: rgba(20, 20, 20, 0.9); 
            backdrop-filter: blur(16px);
            border-radius: 22px; 
            border: 1px solid rgba(255, 255, 255, 0.08); 
            padding: 18px;
            min-height: 0; /* 确保没有强制最小高度，帮助窗口顺利收回 */
        }
        
        .media-cover { border-radius: 12px; }
        .media-title { color: #FFFFFF; font-size: 15px; font-weight: 700; margin-bottom: 2px; }
        .media-artist { color: rgba(255, 255, 255, 0.5); font-size: 12px; }
        
        /* 进度条：极简细线 */
        .media-progress trough { background-color: rgba(255, 255, 255, 0.1); border-radius: 2px; min-height: 2px; }
        .media-progress highlight { background-color: #EBCB8B; border-radius: 2px; }
        .media-progress slider { background-color: #FFFFFF; border-radius: 50%; min-height: 8px; min-width: 8px; margin: -3px 0; }
        
        /* 极简按钮共通 */
        .icon-btn, .text-btn { 
            background: none; 
            border: none; 
            box-shadow: none; 
            color: rgba(255, 255, 255, 0.4); 
            transition: all 0.2s ease;
            outline: none;
        }
        
        .icon-btn:hover, .text-btn:hover { 
            color: #FFFFFF; 
            background-color: rgba(255, 255, 255, 0.06);
            border-radius: 8px;
        }

        .icon-btn { font-family: "JetBrainsMono Nerd Font"; font-size: 18px; min-width: 58px; min-height: 36px; }
        .play-btn { color: #EBCB8B; font-size: 22px; opacity: 0.8; }
        .play-btn:hover { opacity: 1; color: #F0D49F; }

        .text-btn { 
            font-family: "JetBrains Mono"; 
            font-size: 10px; 
            font-weight: 800;
            letter-spacing: 1px;
            min-width: 40px; /* 缩窄避免越界 */
            min-height: 26px; 
        }
        
        .capsule-row { background: transparent; }

        /* 播放列表样式 */
        .playlist-box { background: transparent; }
        .playlist-item { 
            color: rgba(255, 255, 255, 0.7); 
            font-size: 13px; 
            padding: 8px 12px; 
            font-family: "JetBrains Mono", sans-serif;
        }
        .playlist-box row { background: transparent; transition: all 0.2s ease; border-radius: 8px;}
        .playlist-box row:hover { background-color: rgba(255, 255, 255, 0.08); }
        .playlist-box row:selected { background-color: rgba(255, 255, 255, 0.15); color: #FFFFFF;}
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def on_seek_requested(self, scale):
        if scale.has_focus():
            self.run_mpc(["seek", f"{int(scale.get_adjustment().get_value())}%"])

    def toggle_playlist(self, widget):
        is_open = self.playlist_revealer.get_reveal_child()

        if not is_open:
            # 准备展开
            self.refresh_playlist_data()
            self.playlist_revealer.set_reveal_child(True)
        else:
            # 准备收起
            self.playlist_revealer.set_reveal_child(False)
            self._shrink_window()

    def on_playlist_row_activated(self, listbox, row):
        if hasattr(row, "song_pos") and row.song_pos:
            self.run_mpc(["play", str(row.song_pos)])
            self.play_btn.grab_focus()

            # 点击后自动收起
            self.playlist_revealer.set_reveal_child(False)
            self._shrink_window()

    def _shrink_window(self):
        """核心修复：强制撤销 Wayland 的顶级窗口尺寸记忆"""
        # 1. 立即重置默认大小，告诉 Wayland "我不需要那么大了"
        self.set_default_size(0, 0)

        # 2. Revealer 的收起动画默认大约需要 250ms。
        # 我们在 300ms 后（动画彻底结束时）再重置一次，确保窗口完美贴合。
        GLib.timeout_add(300, lambda: self.set_default_size(0, 0) or False)

    def refresh_playlist_data(self):
        # 清空现有列表
        while child := self.playlist_box.get_first_child():
            self.playlist_box.remove(child)

        # 改用最基础的 mpc playlist 命令，兼容所有版本的 mpc
        output = self.run_mpc(["playlist"])
        if not output:
            lbl = Gtk.Label(label="📭 播放列表为空")
            lbl.add_css_class("playlist-item")
            self.playlist_box.append(lbl)
            return

        lines = [line.strip() for line in output.split("\n") if line.strip()]
        for i, line in enumerate(lines, 1):
            display_text = f"{i}. {line}"

            label = Gtk.Label(label=display_text)
            label.set_halign(Gtk.Align.START)
            label.set_ellipsize(3)  # 过长显示省略号
            label.add_css_class("playlist-item")

            row = Gtk.ListBoxRow()
            row.set_child(label)
            row.song_pos = i  # 绑定播放序号
            self.playlist_box.append(row)

    def clear_cover(self):
        self.cover_image.set_from_icon_name("audio-x-generic-symbolic")
        self.cover_image.set_pixel_size(110)

    def run_mpc(self, args):
        try:
            return subprocess.run(
                ["mpc"] + args, capture_output=True, text=True
            ).stdout.strip()
        except:
            return ""

    def load_cover_to_widget(self, path):
        try:
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, 110, 110, True)
            texture = Gdk.Texture.new_for_pixbuf(pixbuf)
            self.cover_image.set_from_paintable(texture)
        except:
            self.clear_cover()

    def mpd_status_loop(self):
        re_percent = re.compile(r"\((\d+)%\)")
        while self.is_running:
            output = self.run_mpc([])
            status_icon, title, artist, current_file, percent = (
                "󰐊",
                "未播放",
                "Unknown",
                "",
                0,
            )
            if output:
                lines = output.split("\n")
                if len(lines) >= 2 and (
                    "[playing]" in lines[1] or "[paused]" in lines[1]
                ):
                    status_icon = "󰏤" if "[playing]" in lines[1] else "󰐊"
                    title = self.run_mpc(
                        ["current", "-f", "%title%"]
                    ) or os.path.basename(self.run_mpc(["current", "-f", "%file%"]))
                    artist = self.run_mpc(["current", "-f", "%artist%"])
                    current_file = self.run_mpc(["current", "-f", "%file%"])
                    match = re_percent.search(lines[1])
                    if match:
                        percent = int(match.group(1))

            GLib.idle_add(
                self.refresh_ui, title, artist, status_icon, current_file, percent
            )
            time.sleep(0.8)

    def refresh_ui(self, title, artist, status, current_file, percent):
        self.title_label.set_text(title)
        self.artist_label.set_text(artist)
        self.play_btn.set_label(status)
        if not self.progress_bar.has_focus():
            self.adj.set_value(percent)
        if current_file != self.current_song_file:
            self.current_song_file = current_file
            if not current_file:
                self.clear_cover()
            else:
                threading.Thread(
                    target=self.extract_cover_async, args=(current_file,), daemon=True
                ).start()

    def extract_cover_async(self, song_file):
        res = subprocess.run(["mpc", "readpicture", song_file], capture_output=True)
        if res.returncode == 0 and len(res.stdout) > 0:
            with open(TARGET_TMP_COVER, "wb") as f:
                f.write(res.stdout)
            GLib.idle_add(self.load_cover_to_widget, TARGET_TMP_COVER)
        else:
            GLib.idle_add(self.clear_cover)


class AppDaemon(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="org.wayland.mediacontrol.daemon")
        self.win = None

    def do_activate(self):
        if not self.win:
            self.win = MediaControlCenter(self)
        self.win.set_visible(True)
        self.win.present()


if __name__ == "__main__":
    app = AppDaemon()
    app.run(sys.argv)


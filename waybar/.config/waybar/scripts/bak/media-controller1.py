#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：media-controller-direct.py
# Description：高颜值全功能控制条版独立媒体控制器（原生 MPD 六键联动、焦点自适应关闭）

import os
import subprocess
import threading
import time

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk

# 尝试导入 Wayland Layer Shell 协议支持
try:
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import GtkLayerShell

    HAS_LAYER_SHELL = True
except (ValueError, ImportError):
    HAS_LAYER_SHELL = False

# 临时存放封面图片的路径
TARGET_TMP_COVER = "/tmp/mpd_direct_current_cover.jpg"


class MediaControlCenter(Gtk.Window):
    def __init__(self):
        super().__init__(title="Media Control Center")

        # 记录当前的歌曲标识，避免高频重复刷盘卡顿
        self.current_song_file = ""

        # ---- Wayland Layer Shell 核心配置 ----
        if HAS_LAYER_SHELL:
            GtkLayerShell.init_for_window(self)
            GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
            GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)

            # 右上角绝对锚定
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        else:
            self.set_decorated(False)
            self.set_keep_above(True)
            self.set_position(Gtk.WindowPosition.CENTER)

        # 支持半透明底色
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        # 修正弃用警告：使用 screen.is_composited() 代替 self.is_composited()
        if visual and screen.is_composited():
            self.set_visual(visual)

        # 真正的媒体控制面板主体盒子
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        main_vbox.set_margin_top(1)
        main_vbox.set_margin_bottom(15)
        main_vbox.set_margin_start(15)
        main_vbox.set_margin_end(385)
        main_vbox.get_style_context().add_class("media-panel")
        self.add(main_vbox)

        # ---- 左右分栏布局容器 ----
        content_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        content_hbox.set_margin_start(12)
        content_hbox.set_margin_end(12)
        content_hbox.set_margin_top(10)
        content_hbox.set_margin_bottom(10)
        main_vbox.pack_start(content_hbox, True, True, 0)

        # 左侧：专辑封面
        self.cover_image = Gtk.Image()
        self.cover_image.get_style_context().add_class("media-cover")
        self.clear_cover()
        content_hbox.pack_start(self.cover_image, False, False, 0)

        # 右侧：歌曲信息 + 两个功能胶囊舱
        right_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        content_hbox.pack_start(right_vbox, True, True, 0)

        # 歌曲信息展示
        info_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        right_vbox.pack_start(info_vbox, False, False, 0)

        self.title_label = Gtk.Label(label="未检测到播放媒体")
        self.title_label.set_halign(Gtk.Align.START)
        self.title_label.get_style_context().add_class("media-title")
        self.title_label.set_ellipsize(3)
        info_vbox.pack_start(self.title_label, False, False, 0)

        self.artist_label = Gtk.Label(label="Unknown Artist")
        self.artist_label.set_halign(Gtk.Align.START)
        self.artist_label.get_style_context().add_class("media-artist")
        self.artist_label.set_ellipsize(3)
        info_vbox.pack_start(self.artist_label, False, False, 0)

        # 1️⃣ 第一层：核心播放控制组合盒（胶囊舱 1）
        ctrl_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        ctrl_hbox.set_halign(Gtk.Align.START)
        ctrl_hbox.get_style_context().add_class("button-capsule")
        right_vbox.pack_start(ctrl_hbox, False, False, 0)

        self.prev_btn = Gtk.Button(label="prev")
        self.prev_btn.get_style_context().add_class("nav-btn")
        self.prev_btn.connect("clicked", lambda w: self.run_mpc(["prev"]))
        ctrl_hbox.pack_start(self.prev_btn, False, False, 0)

        self.play_btn = Gtk.Button(label="play")
        self.play_btn.get_style_context().add_class("play-btn")
        self.play_btn.connect("clicked", lambda w: self.run_mpc(["toggle"]))
        ctrl_hbox.pack_start(self.play_btn, False, False, 0)

        self.next_btn = Gtk.Button(label="next")
        self.next_btn.get_style_context().add_class("nav-btn")
        self.next_btn.connect("clicked", lambda w: self.run_mpc(["next"]))
        ctrl_hbox.pack_start(self.next_btn, False, False, 0)

        # 2️⃣ 🛠️ 第二层：高级系统指令组合盒（胶囊舱 2）
        sys_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        sys_hbox.set_halign(Gtk.Align.START)
        sys_hbox.get_style_context().add_class("button-capsule")
        sys_hbox.get_style_context().add_class("sys-capsule")
        right_vbox.pack_start(sys_hbox, False, False, 0)

        # mpc clear 按钮
        self.clear_btn = Gtk.Button(label="clr")
        self.clear_btn.get_style_context().add_class("func-btn")
        self.clear_btn.set_tooltip_text("清空当前播放列表")
        self.clear_btn.connect("clicked", lambda w: self.run_mpc(["clear"]))
        sys_hbox.pack_start(self.clear_btn, False, False, 0)

        # mpc update 按钮
        self.update_btn = Gtk.Button(label="sync")
        self.update_btn.get_style_context().add_class("func-btn")
        self.update_btn.set_tooltip_text("扫描并更新音乐库")
        self.update_btn.connect("clicked", lambda w: self.run_mpc(["update"]))
        sys_hbox.pack_start(self.update_btn, False, False, 0)

        # mpc add / 按钮
        self.add_btn = Gtk.Button(label="all+")
        self.add_btn.get_style_context().add_class("func-btn")
        self.add_btn.set_tooltip_text("添加全部音乐到队列")
        self.add_btn.connect("clicked", lambda w: self.run_mpc(["add", "/"]))
        sys_hbox.pack_start(self.add_btn, False, False, 0)

        # ---- 核心焦点关闭绑定 ----
        self.connect("key-press-event", self.on_key_press)
        self.connect("focus-out-event", lambda w, e: self.close_program())

        self.apply_css()

        # 启动纯粹的 MPD 监听线程
        self.is_running = True
        threading.Thread(target=self.mpd_status_loop, daemon=True).start()

    def apply_css(self):
        css = """
        window { background-color: transparent; }
        
        /* 1. 主面板深邃极简质感 - 已去除半透明与阴影 */
        .media-panel {
            background-color: #17191e;
            border-radius: 20px;
            border: 1px solid rgba(255, 255, 255, 0.05);
            box-shadow: none;
            min-width: 380px;
        }
        .media-cover { 
            border-radius: 12px; 
            background-color: rgba(255, 255, 255, 0.02);
        }
        .media-title { 
            color: #FFFFFF; 
            font-size: 14px; 
            font-weight: 600; 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }
        .media-artist { 
            color: #717782; 
            font-size: 12px; 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }

        /* 2. 几何胶囊化容器统一化 */
        .button-capsule {
            background-color: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.02);
            border-radius: 10px;
            padding: 3px;
        }
        
        .sys-capsule {
            background-color: rgba(255, 255, 255, 0.01);
            margin-top: -2px;
        }

        /* 3. 极简按钮规范 */
        .button-capsule button {
            background-image: none;
            background-color: transparent;
            border: none;
            box-shadow: none;
            text-shadow: none;
            color: #8C929D;
            font-family: "JetBrains Mono", "SF Pro Text", "Fira Code", monospace;
            font-size: 11px;
            font-weight: 500;
            min-width: 54px;
            min-height: 28px;
            border-radius: 7px;
            padding: 0px 8px;
            /* 移除 transition 中的 all，部分低版本旧 GTK 会在此产生解析隐患 */
            transition: background-color 0.15s ease-out;
        }

        /* 悬停微亮反馈 */
        .button-capsule button:hover {
            background-color: rgba(255, 255, 255, 0.06);
            color: #FFFFFF;
        }

        /* 激活状态：移除不合规的 transform，改用内边距下压和加深背景色 */
        .button-capsule button:active {
            background-color: rgba(0, 0, 0, 0.3);
            padding-top: 2px;
        }

        /* 播放键特异化 */
        .button-capsule button.play-btn {
            color: #EBCB8B;
            font-weight: 700;
        }
        .button-capsule button.play-btn:hover {
            background-color: rgba(235, 203, 139, 0.1);
            color: #FFE4A0;
        }
        .button-capsule button.play-btn:active {
            background-color: rgba(235, 203, 139, 0.2);
        }

        /* 系统功能键微调 */
        .button-capsule button.func-btn {
            color: #616773;
        }
        .button-capsule button.func-btn:hover {
            background-color: rgba(255, 255, 255, 0.04);
            color: #A3BE8C;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

    def clear_cover(self):
        self.cover_image.set_from_icon_name("audio-x-generic", Gtk.IconSize.DIALOG)

    def run_mpc(self, args):
        try:
            res = subprocess.run(["mpc"] + args, capture_output=True, text=True)
            return res.stdout.strip()
        except Exception:
            return ""

    def mpd_status_loop(self):
        while self.is_running:
            title = "未检测到播放媒体"
            artist = "Unknown Artist"
            status_text = "play"
            current_file = ""

            output = self.run_mpc([])
            if output:
                lines = output.split("\n")
                if len(lines) >= 2 and (
                    "[playing]" in lines[1] or "[paused]" in lines[1]
                ):
                    status_text = "pause" if "[playing]" in lines[1] else "play"

                    title = self.run_mpc(["current", "-f", "%title%"])
                    artist = self.run_mpc(["current", "-f", "%artist%"])
                    current_file = self.run_mpc(["current", "-f", "%file%"])

                    if not title and current_file:
                        title = os.path.basename(current_file)
                    if not artist:
                        artist = "未知艺术家"

            GLib.idle_add(self.refresh_ui, title, artist, status_text, current_file)
            time.sleep(0.4)

    def refresh_ui(self, title, artist, status_text, current_file):
        if not self.is_running:
            return
        self.title_label.set_text(title)
        self.artist_label.set_text(artist)
        self.play_btn.set_label(status_text)

        if current_file != self.current_song_file:
            self.current_song_file = current_file

            if not current_file:
                self.clear_cover()
                return

            threading.Thread(
                target=self.extract_cover_async,
                args=(current_file,),
                daemon=True,
            ).start()

    def extract_cover_async(self, song_file):
        try:
            if os.path.exists(TARGET_TMP_COVER):
                os.remove(TARGET_TMP_COVER)

            res = subprocess.run(["mpc", "readpicture", song_file], capture_output=True)
            if res.returncode == 0 and len(res.stdout) > 0:
                with open(TARGET_TMP_COVER, "wb") as f:
                    f.write(res.stdout)

                GLib.idle_add(self.load_cover_to_widget, TARGET_TMP_COVER)
                return
        except Exception:
            pass

        GLib.idle_add(self.clear_cover)

    def load_cover_to_widget(self, path):
        try:
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                path, width=88, height=88, preserve_aspect_ratio=True
            )
            self.cover_image.set_from_pixbuf(pixbuf)
        except Exception:
            self.clear_cover()

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_program()

    def close_program(self):
        if self.is_running:
            self.is_running = False
            if os.path.exists(TARGET_TMP_COVER):
                try:
                    os.remove(TARGET_TMP_COVER)
                except Exception:
                    pass
            self.destroy()
            Gtk.main_quit()
        return False


if __name__ == "__main__":
    win = MediaControlCenter()
    win.connect("destroy", lambda w: win.close_program())
    win.show_all()
    Gtk.main()

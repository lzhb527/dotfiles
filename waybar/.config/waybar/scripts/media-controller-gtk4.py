#!/usr/bin/env python3
# -*- coding:utf-8 -*-
"""
Filename：media-controller-daemon.py
Description：常驻后台版 - 胶囊媒体控制器（GTK4 + 失去焦点自动隐藏）
"""

import os
import subprocess
import sys
import threading
import time

import gi

# 强制开启 Cairo 软件渲染，保障秒弹速度
os.environ["GSK_RENDERER"] = "cairo"

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk

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

        self.current_song_file = ""
        self.is_running = True

        # ---- Layer Shell 核心配置 ----
        if HAS_LAYER_SHELL:
            Gtk4LayerShell.init_for_window(self)
            Gtk4LayerShell.set_layer(self, Gtk4LayerShell.Layer.TOP)
            Gtk4LayerShell.set_keyboard_mode(
                self, Gtk4LayerShell.KeyboardMode.ON_DEMAND
            )
            Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.TOP, True)
            Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.RIGHT, True)
        else:
            self.set_titlebar(Gtk.Box())
            self.set_keep_above(True) if hasattr(self, "set_keep_above") else None

        # ---- UI 布局 构建 ----
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        main_vbox.set_margin_top(1)
        main_vbox.set_margin_bottom(15)
        main_vbox.set_margin_start(15)
        main_vbox.set_margin_end(15)
        main_vbox.add_css_class("media-panel")
        self.set_child(main_vbox)

        content_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        content_hbox.set_margin_start(12)
        content_hbox.set_margin_end(12)
        content_hbox.set_margin_top(10)
        content_hbox.set_margin_bottom(10)
        main_vbox.append(content_hbox)

        self.cover_image = Gtk.Image()
        self.cover_image.add_css_class("media-cover")
        self.clear_cover()
        content_hbox.append(self.cover_image)

        right_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        content_hbox.append(right_vbox)

        info_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        right_vbox.append(info_vbox)

        self.title_label = Gtk.Label(label="未检测到播放媒体")
        self.title_label.set_halign(Gtk.Align.START)
        self.title_label.add_css_class("media-title")
        self.title_label.set_ellipsize(3)
        info_vbox.append(self.title_label)

        self.artist_label = Gtk.Label(label="Unknown Artist")
        self.artist_label.set_halign(Gtk.Align.START)
        self.artist_label.add_css_class("media-artist")
        self.artist_label.set_ellipsize(3)
        info_vbox.append(self.artist_label)

        # 胶囊舱 1
        ctrl_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        ctrl_hbox.set_halign(Gtk.Align.START)
        ctrl_hbox.add_css_class("button-capsule")
        right_vbox.append(ctrl_hbox)

        self.prev_btn = Gtk.Button(label="prev")
        self.prev_btn.connect("clicked", lambda w: self.run_mpc(["prev"]))
        ctrl_hbox.append(self.prev_btn)

        self.play_btn = Gtk.Button(label="play")
        self.play_btn.add_css_class("play-btn")
        self.play_btn.connect("clicked", lambda w: self.run_mpc(["toggle"]))
        ctrl_hbox.append(self.play_btn)

        self.next_btn = Gtk.Button(label="next")
        self.next_btn.connect("clicked", lambda w: self.run_mpc(["next"]))
        ctrl_hbox.append(self.next_btn)

        # 胶囊舱 2
        sys_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        sys_hbox.set_halign(Gtk.Align.START)
        sys_hbox.add_css_class("button-capsule")
        sys_hbox.add_css_class("sys-capsule")
        right_vbox.append(sys_hbox)

        self.clear_btn = Gtk.Button(label="clr")
        self.clear_btn.set_tooltip_text("清空当前播放列表")
        self.clear_btn.connect("clicked", lambda w: self.run_mpc(["clear"]))
        sys_hbox.append(self.clear_btn)

        self.update_btn = Gtk.Button(label="sync")
        self.update_btn.set_tooltip_text("扫描并更新音乐库")
        self.update_btn.connect("clicked", lambda w: self.run_mpc(["update"]))
        sys_hbox.append(self.update_btn)

        self.add_btn = Gtk.Button(label="all+")
        self.add_btn.set_tooltip_text("添加全部音乐到队列")
        self.add_btn.connect("clicked", lambda w: self.run_mpc(["add", "/"]))
        sys_hbox.append(self.add_btn)

        # ---- 事件控制器 (隐藏代替销毁) ----
        key_controller = Gtk.EventControllerKey()
        key_controller.connect("key-pressed", self.on_key_press)
        self.add_controller(key_controller)

        focus_controller = Gtk.EventControllerFocus()
        focus_controller.connect("leave", lambda c: self.hide_window())
        self.add_controller(focus_controller)

        # 处理点击关闭按钮等默认信号（接管销毁信号）
        self.connect("close-request", lambda w: self.hide_window())

        self.apply_css()
        threading.Thread(target=self.mpd_status_loop, daemon=True).start()

    def apply_css(self):
        # 保持与之前一致的 CSS 样式
        css = """
        window { background-color: transparent; }
        .media-panel { background-color: rgba(22, 22, 22, 0.92); border-radius: 20px; border: 1px solid rgba(255, 255, 255, 0.06); min-width: 380px; }
        .media-cover { border-radius: 12px; background-color: rgba(255, 255, 255, 0.02); }
        .media-title { color: #FFFFFF; font-size: 14px; font-weight: 600; }
        .media-artist { color: #8C929D; font-size: 12px; }
        .button-capsule { background-color: rgba(255, 255, 255, 0.04); border: 1px solid rgba(255, 255, 255, 0.01); border-radius: 10px; padding: 3px; }
        .sys-capsule { background-color: rgba(255, 255, 255, 0.01); margin-top: -2px; }
        .button-capsule button { background-image: none; background-color: transparent; border: none; box-shadow: none; color: #A0A6B2; font-family: "JetBrains Mono", monospace; font-size: 11px; font-weight: 500; min-width: 58px; min-height: 28px; border-radius: 7px; padding: 0px 8px; transition: background-color 0.15s ease-out, color 0.15s ease-out; }
        .button-capsule button:hover { background-color: rgba(255, 255, 255, 0.08); color: #FFFFFF; }
        .button-capsule button:active { background-color: rgba(0, 0, 0, 0.4); }
        .button-capsule button.play-btn { color: #EBCB8B; font-weight: 700; }
        .button-capsule button.play-btn:hover { background-color: rgba(235, 203, 139, 0.12); color: #FFE4A0; }
        .button-capsule button.func-btn { color: #6A717F; }
        .button-capsule button.func-btn:hover { background-color: rgba(163, 190, 140, 0.1); color: #A3BE8C; }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def hide_window(self):
        """核心重构：隐藏窗口，而不是退出进程"""
        self.hide()
        return True  # 返回 True 阻止默认的销毁逻辑

    def clear_cover(self):
        self.cover_image.set_from_icon_name("audio-x-generic")
        self.cover_image.set_pixel_size(88)

    def run_mpc(self, args):
        try:
            res = subprocess.run(["mpc"] + args, capture_output=True, text=True)
            return res.stdout.strip()
        except Exception:
            return ""

    def mpd_status_loop(self):
        while self.is_running:
            title, artist, status_text, current_file = (
                "未检测到播放媒体",
                "Unknown Artist",
                "play",
                "",
            )
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
        self.title_label.set_text(title)
        self.artist_label.set_text(artist)
        self.play_btn.set_label(status_text)
        if current_file != self.current_song_file:
            self.current_song_file = current_file
            if not current_file:
                self.clear_cover()
                return
            threading.Thread(
                target=self.extract_cover_async, args=(current_file,), daemon=True
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

    def on_key_press(self, controller, keyval, keycode, state):
        if keyval == Gdk.KEY_Escape:
            self.hide_window()
            return True
        return False


# ---- 单例守护进程核心控制 ----
class AppDaemon(Gtk.Application):
    def __init__(self):
        # 使用唯一实例 ID，确保 D-Bus 能够精确传递信号
        super().__init__(application_id="org.wayland.mediacontrol.daemon")
        self.win = None

    def do_activate(self):
        """当第一次启动，或者后续通过运行相同命令触发时执行"""
        if not self.win:
            # 第一次运行：创建窗口
            self.win = MediaControlCenter(self)

        # 无论是第一次还是后续触发，都将其展现（唤醒）
        self.win.present()


if __name__ == "__main__":
    app = AppDaemon()
    # 允许接收外部命令行传参重复激活
    app.run(sys.argv)

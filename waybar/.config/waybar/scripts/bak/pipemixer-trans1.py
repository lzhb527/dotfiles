#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：volume-control.py
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-25 10:35:00
# Description：精简版独立音量控制面板（现代轻量焦点自适应关闭版）
# Copyright (C) 2026 Ltd. All rights reserved.

import re
import subprocess
import threading

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gdk, GLib, Gtk

# 尝试导入 Wayland Layer Shell 协议支持
try:
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import GtkLayerShell

    HAS_LAYER_SHELL = True
except (ValueError, ImportError):
    HAS_LAYER_SHELL = False


class VolumeControlCenter(Gtk.Window):
    def __init__(self):
        super().__init__(title="Volume Control Center")

        # ---- Wayland Layer Shell 核心配置 ----
        if HAS_LAYER_SHELL:
            GtkLayerShell.init_for_window(self)
            GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
            GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)

            # 🛠️ 【机制改动 1】移除全屏拉伸，改为真正的右上角锚定
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        else:
            self.set_decorated(False)
            self.set_keep_above(True)
            self.set_position(Gtk.WindowPosition.CENTER)

        # 强力支持半透明底色
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and self.is_composited():
            self.set_visual(visual)

        # ---- 真正的音量控制面板主体盒子 ----
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        main_vbox.set_margin_top(2)
        main_vbox.set_margin_bottom(20)
        main_vbox.set_margin_start(20)
        main_vbox.set_margin_end(2)

        # 给面板绑定特定 CSS 类名
        main_vbox.get_style_context().add_class("volume-panel")
        self.add(main_vbox)

        # ---- 顶层布局：静音按钮 + 动态文字状态 ----
        header_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        main_vbox.pack_start(header_hbox, False, False, 0)

        self.mute_btn = Gtk.Button(label="🎵")
        self.mute_btn.get_style_context().add_class("mute-btn")
        self.mute_btn.connect("clicked", self.toggle_mute)
        header_hbox.pack_start(self.mute_btn, False, False, 0)

        self.status_label = Gtk.Label(label="正在同步系统音量...")
        self.status_label.set_halign(Gtk.Align.START)
        header_hbox.pack_start(self.status_label, True, True, 0)

        # ---- 音量调节核心滑动条 ----
        self.volume_scale = Gtk.Scale.new_with_range(
            Gtk.Orientation.HORIZONTAL, 0, 100, 1
        )
        self.volume_scale.set_draw_value(True)
        self.volume_scale.set_value_pos(Gtk.PositionType.RIGHT)
        self.volume_scale.connect("value-changed", self.on_volume_slider_changed)
        main_vbox.pack_start(self.volume_scale, True, True, 0)

        # ---- 🛠️ 【机制改动 2】核心事件驱动绑定 ----
        # 监听按键
        self.connect("key-press-event", self.on_key_press)
        # 核心：一旦用户鼠标点击窗口外部，或者焦点切换，立刻优雅退出
        self.connect("focus-out-event", lambda w, e: self.close_program())

        # 4. 样式美化
        self.apply_css()

        # 5. 开启后台异步加载初始化状态
        threading.Thread(target=self.update_system_status, daemon=True).start()

    def apply_css(self):
        css = """
        /* 移除原本的全屏隐形，让窗口本身回归纯粹 */
        window {
            background-color: transparent;
        }
        /* 真正的音量悬浮窗样式 */
        .volume-panel {
            background-color: rgba(46, 52, 64, 0.95);
            border-radius: 16px;
            border: 1px solid rgba(255, 255, 255, 0.1);
            min-width: 260px;
        }
        label {
            color: #ECEFF4;
            font-size: 14px;
            font-weight: bold;
        }
        button.mute-btn {
            background-color: rgba(67, 76, 94, 0.6);
            border: none;
            border-radius: 8px;
            padding: 4px 10px;
            font-size: 16px;
        }
        button.mute-btn:hover {
            background-color: #5E81AC;
        }
        scale contents trough highlight {
            background-color: #88C0D0;
            border-radius: 4px;
        }
        scale contents trough {
            background-color: #434C5E;
            border-radius: 4px;
            min-height: 8px;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    # ---- 数据采集与同步 ----
    def update_system_status(self):
        vol_str = "未知"
        vol_val = 50
        is_muted = False
        try:
            res = subprocess.run(
                ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"],
                capture_output=True,
                text=True,
            )
            match = re.search(r"Volume:\s+([0-9.]+)(.*?)$", res.stdout)
            if match:
                vol_val = int(float(match.group(1)) * 100)
                vol_str = f"{vol_val}%"
                if "MUTED" in match.group(2):
                    vol_str = "已静音"
                    is_muted = True
        except Exception:
            pass

        GLib.idle_add(self.refresh_ui_labels, vol_str, vol_val, is_muted)

    def refresh_ui_labels(self, vol_str, vol_val, is_muted):
        if is_muted:
            self.status_label.set_markup(
                "🎵 <b>系统当前音量:</b> <span color='#BF616A'>已静音</span>"
            )
            self.mute_btn.set_label("🔇")
        else:
            self.status_label.set_markup(f"🎵 <b>系统当前音量:</b> {vol_str}")
            self.mute_btn.set_label("🔊")

        self.volume_scale.handler_block_by_func(self.on_volume_slider_changed)
        self.volume_scale.set_value(vol_val)
        self.volume_scale.handler_unblock_by_func(self.on_volume_slider_changed)

    # ---- 反向控制动作 ----
    def on_volume_slider_changed(self, slider):
        val = slider.get_value()
        volume_float = val / 100.0
        subprocess.Popen(
            [
                "wpctl",
                "set-volume",
                "@DEFAULT_AUDIO_SINK@",
                f"{volume_float:.2f}",
            ]
        )
        self.status_label.set_markup(f"🎵 <b>系统当前音量:</b> {int(val)}%")
        self.mute_btn.set_label("🔊")

    def toggle_mute(self, button):
        subprocess.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        self.update_system_status()

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_program()

    def close_program(self):
        self.destroy()
        Gtk.main_quit()
        return False


if __name__ == "__main__":
    win = VolumeControlCenter()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

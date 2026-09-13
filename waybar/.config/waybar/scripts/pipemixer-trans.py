#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：volume-control.py
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-25 10:35:00
# Description：精简版独立音量控制面板（现代轻量焦点自适应关闭版 - 极简纯色硬朗风格）
# Copyright (C) 2026 Ltd. All rights reserved.

import re
import subprocess
import threading

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
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

            # 🛠️ 真正的右上角锚定
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        else:
            self.set_decorated(False)
            self.set_keep_above(True)
            self.set_position(Gtk.WindowPosition.CENTER)

        # 支持底色配置
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        # 修正弃用警告：使用 screen.is_composited() 代替 self.is_composited()
        if visual and screen.is_composited():
            self.set_visual(visual)

        # ---- 真正的音量控制面板主体盒子 ----
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        main_vbox.set_margin_top(1)
        main_vbox.set_margin_bottom(15)
        main_vbox.set_margin_start(15)
        main_vbox.set_margin_end(1)

        # 给面板绑定特定 CSS 类名
        main_vbox.get_style_context().add_class("volume-panel")
        self.add(main_vbox)

        # ---- 顶层布局：静音按钮 + 动态文字状态 ----
        header_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        header_hbox.set_margin_start(4)
        header_hbox.set_margin_end(4)
        main_vbox.pack_start(header_hbox, False, False, 0)

        # 静音胶囊舱包裹
        btn_capsule = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        btn_capsule.get_style_context().add_class("button-capsule")
        header_hbox.pack_start(btn_capsule, False, False, 0)

        self.mute_btn = Gtk.Button(label="🎵")
        self.mute_btn.get_style_context().add_class("mute-btn")
        self.mute_btn.connect("clicked", self.toggle_mute)
        btn_capsule.pack_start(self.mute_btn, False, False, 0)

        self.status_label = Gtk.Label(label="正在同步系统音量...")
        self.status_label.set_halign(Gtk.Align.START)
        self.status_label.get_style_context().add_class("volume-title")
        header_hbox.pack_start(self.status_label, True, True, 0)

        # ---- 音量调节核心滑动条 ----
        self.volume_scale = Gtk.Scale.new_with_range(
            Gtk.Orientation.HORIZONTAL, 0, 100, 1
        )
        self.volume_scale.set_draw_value(True)
        self.volume_scale.set_value_pos(Gtk.PositionType.RIGHT)
        self.volume_scale.get_style_context().add_class("volume-slider")
        self.volume_scale.connect("value-changed", self.on_volume_slider_changed)

        # 让滑动条两侧带点呼吸内衬
        slider_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        slider_box.set_margin_start(4)
        slider_box.set_margin_end(4)
        slider_box.pack_start(self.volume_scale, True, True, 0)
        main_vbox.pack_start(slider_box, True, True, 0)

        # ---- 核心事件驱动绑定 ----
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
        window {
            background-color: transparent;
        }
        
        /* 1. 主面板深邃极简质感 - 已去除半透明与阴影 */
        .volume-panel {
            background-color: rgba(22, 22, 22, 0.85);
            border-radius: 20px;
            border: 1px solid rgba(255, 255, 255, 0.05);
            box-shadow: none;
            min-width: 300px;
        }
        
        .volume-title {
            color: #FFFFFF;
            font-size: 13px;
            font-weight: 600;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }
        
        /* 2. 几何胶囊化容器统一化 */
        .button-capsule {
            background-color: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.02);
            border-radius: 10px;
            padding: 3px;
        }
        
        /* 3. 极简静音按钮规范 */
        .button-capsule button.mute-btn {
            background-image: none;
            background-color: rgba(22, 22, 22, 0.3);
            border: none;
            box-shadow: none;
            text-shadow: none;
            color: #ffffff;
            font-size: 14px;
            min-width: 36px;
            min-height: 28px;
            border-radius: 7px;
            padding: 0px;
            transition: background-color 0.15s ease-out;
        }
        
        .button-capsule button.mute-btn:hover {
            background-color: rgba(255, 255, 255, 0.06);
            color: #EBCB8B;
        }
        
        .button-capsule button.mute-btn:active {
            background-color: rgba(0, 0, 0, 0.9);
            padding-top: 2px;
        }

        /* 4. 极简现代槽线滑动条设计 */
        scale.volume-slider contents trough {
            background-color: rgba(255, 255, 255, 0.05);
            border: none;
            border-radius: 6px;
            min-height: 8px;
        }
        
        scale.volume-slider contents trough highlight {
            background-image: none;
            background-color: #f9e2af;
            border-radius: 6px;
        }
        
        scale.volume-slider contents slider {
            background-image: none;
            background-color: #ECEFF4;
            border: none;
            border-radius: 50%;
            min-width: 14px;
            min-height: 14px;
            margin: -3px 0px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.4);
        }
        
        scale.volume-slider text {
            color: #717782;
            font-family: "JetBrains Mono", "Fira Code", monospace;
            font-size: 11px;
            font-weight: 500;
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
                "<b>系统音量:</b> <span color='#BF616A'>已静音</span>"
            )
            self.mute_btn.set_label(" ")
        else:
            self.status_label.set_markup(f"<b>系统音量:</b> {vol_str}")
            self.mute_btn.set_label(" ")

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
        self.status_label.set_markup(f"<b>系统音量:</b> {int(val)}%")
        self.mute_btn.set_label(" ")

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

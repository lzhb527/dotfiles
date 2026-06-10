#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：control-center.py
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-25 08:15:45
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
import re
import subprocess
import threading

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gdk, GLib, Gtk


class ControlCenter(Gtk.Window):
    def __init__(self):
        super().__init__(title="Quick Control Center")

        # 1. 窗口基础设置：去掉边框，让它看起来像一个悬浮面板
        self.set_decorated(False)
        self.set_default_size(360, 400)
        self.set_keep_above(True)  # 让它保持在最上层
        self.set_position(Gtk.WindowPosition.CENTER)  # 居中弹出

        # 支持半透明底色
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and self.is_composited():
            self.set_visual(visual)

        # 2. 界面核心布局（垂直大盒子）
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        main_vbox.set_margin_top(25)
        main_vbox.set_margin_bottom(25)
        main_vbox.set_margin_start(25)
        main_vbox.set_margin_end(25)
        self.add(main_vbox)

        # ---- 模块一：顶部状态标签 ----
        self.status_label = Gtk.Label(label="正在读取系统状态...")
        self.status_label.set_halign(Gtk.Align.START)
        main_vbox.pack_start(self.status_label, False, False, 0)

        # ---- 模块二：大图标快捷按钮网格 (2x2) ----
        grid = Gtk.Grid()
        grid.set_column_spacing(15)
        grid.set_row_spacing(15)
        grid.set_row_homogeneous(True)
        grid.set_column_homogeneous(True)
        main_vbox.pack_start(grid, True, True, 0)

        # 按钮 1：一键静音/取消静音
        self.mute_btn = Gtk.Button(label="🔇\n静音切换")
        self.mute_btn.connect("clicked", self.toggle_mute)
        grid.attach(self.mute_btn, 0, 0, 1, 1)

        # 按钮 2：深色模式切换
        self.theme_btn = Gtk.Button(label="🌙\n暗黑模式")
        self.theme_btn.connect("clicked", self.toggle_theme)
        grid.attach(self.theme_btn, 1, 0, 1, 1)

        # 按钮 3：锁屏
        lock_btn = Gtk.Button(label="🔒\n立即锁屏")
        lock_btn.connect(
            "clicked", lambda w: subprocess.Popen(["loginctl", "lock-session"])
        )
        grid.attach(lock_btn, 0, 1, 1, 1)

        # 按钮 4：关闭控制中心
        exit_btn = Gtk.Button(label="❌\n关闭退出")
        exit_btn.connect("clicked", lambda w: self.close_program())
        grid.attach(exit_btn, 1, 1, 1, 1)

        # ---- 模块三：音量调节滑动条 ----
        volume_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        volume_lbl = Gtk.Label(label="🎵 系统音量调节")
        volume_lbl.set_halign(Gtk.Align.START)

        # 创建滑动条 (范围 0 到 100，步长 1)
        self.volume_scale = Gtk.Scale.new_with_range(
            Gtk.Orientation.HORIZONTAL, 0, 100, 1
        )
        self.volume_scale.set_draw_value(True)  # 显示当前拖动数值
        self.volume_scale.connect("value-changed", self.on_volume_slider_changed)

        volume_box.pack_start(volume_lbl, False, False, 0)
        volume_box.pack_start(self.volume_scale, False, False, 0)
        main_vbox.pack_start(volume_box, False, False, 0)

        # 3. 绑定 ESC 键快速退出
        self.connect("key-press-event", self.on_key_press)

        # 4. 样式美化 (CSS)
        self.apply_css()

        # 5. 异步加载初始化系统状态
        threading.Thread(target=self.update_system_status, daemon=True).start()

    def apply_css(self):
        """给控制中心刷一层好看的 Nord 现代暗色皮肤"""
        # 这里改成了普通字符串，并允许在其中写中文注释
        css = """
        window {
            background-color: rgba(46, 52, 64, 0.95); /* 深蓝灰半透明底色 */
            border-radius: 16px;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        label {
            color: #ECEFF4;
            font-size: 14px;
            font-weight: bold;
        }
        button {
            background-color: rgba(67, 76, 94, 0.8);
            color: #E5E9F0;
            border-radius: 12px;
            border: 0px;
            font-size: 15px;
            font-weight: bold;
            padding: 15px;
        }
        button:hover {
            background-color: #5E81AC; /* 悬浮蓝色 */
            color: #FFFFFF;
        }
        scale contents trough highlight {
            background-color: #88C0D0; /* 滑动条高亮色 */
            border-radius: 4px;
        }
        """
        provider = Gtk.CssProvider()
        # 将普通字符串显式编码为 UTF-8 字节流传递给 GTK
        provider.load_from_data(css.encode("utf-8"))

        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    # ---- 后台数据采集与更新 ----
    def update_system_status(self):
        """在后台线程中获取音量和电量状态"""
        # 1. 获取音量
        vol_str = "未知"
        vol_val = 50
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
                    vol_str += " (已静音)"
        except Exception:
            pass

        # 2. 获取电池电量
        bat_str = "无电池/AC供电"
        try:
            with open("/sys/class/power_supply/BAT0/capacity", "r") as f:
                capacity = f.read().strip()
            with open("/sys/class/power_supply/BAT0/status", "r") as f:
                status = f.read().strip()
            status_cn = "充电中" if status == "Charging" else "放电中"
            bat_str = f"{capacity}% ({status_cn})"
        except Exception:
            pass

        # 将数据送回主线程更新 UI
        GLib.idle_add(self.refresh_ui_labels, vol_str, vol_val, bat_str)

    def refresh_ui_labels(self, vol_str, vol_val, bat_str):
        """主线程：刷新界面上的文本和滑块位置"""
        self.status_label.set_markup(
            f"🔋 <b>系统电量:</b> {bat_str}\n🎵 <b>当前音量:</b> {vol_str}"
        )
        # 暂时断开滑动条的信号绑定，避免设置初始值时误触发命令
        self.volume_scale.handler_block_by_func(self.on_volume_slider_changed)
        self.volume_scale.set_value(vol_val)
        self.volume_scale.handler_unblock_by_func(self.on_volume_slider_changed)

    # ---- 反向控制动作 ----
    def on_volume_slider_changed(self, slider):
        """拖动音量条时，实时调用底层系统命令"""
        val = slider.get_value()
        volume_float = val / 100.0
        subprocess.Popen(
            ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{volume_float:.2f}"]
        )

    def toggle_mute(self, button):
        """点击静音按钮"""
        subprocess.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        self.update_system_status()

    def toggle_theme(self, button):
        """演示切换主题：控制中心自身的暗黑/明亮切换"""
        settings = Gtk.Settings.get_default()
        current = settings.get_property("gtk-application-prefer-dark-theme")
        settings.set_property("gtk-application-prefer-dark-theme", not current)
        button.set_label("☀️\n明亮模式" if not current else "🌙\n暗黑模式")

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_program()

    def close_program(self):
        self.destroy()
        Gtk.main_quit()


if __name__ == "__main__":
    win = ControlCenter()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：system-hud-direct.py
# Description：高颜值全功能系统看板独立控制条（精简版：带实时进度条，透明度 0.85）

import re
import subprocess
import threading
import time

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


class SystemHudCenter(Gtk.Window):
    def __init__(self):
        super().__init__(title="System HUD Center")

        self.is_running = True
        self.last_cpu_work = 0
        self.last_cpu_total = 0

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
        if visual and screen.is_composited():
            self.set_visual(visual)

        # 主面板盒子（像素级同步你的媒体控制条，保持 385px 避让空间）
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        main_vbox.set_margin_top(1)
        main_vbox.set_margin_bottom(15)
        main_vbox.set_margin_start(15)
        main_vbox.set_margin_end(385)  # 保持纵向完美对齐
        main_vbox.get_style_context().add_class("hud-panel")
        self.add(main_vbox)

        # ---- 内部边距布局容器 ----
        content_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        content_vbox.set_margin_start(14)
        content_vbox.set_margin_end(14)
        content_vbox.set_margin_top(12)
        content_vbox.set_margin_bottom(12)
        main_vbox.pack_start(content_vbox, True, True, 0)

        # ==========================================
        # 资源状态展示区（点击唤出 htop）
        # ==========================================
        info_btn = Gtk.Button()
        info_btn.get_style_context().add_class("info-area")
        info_btn.connect(
            "clicked", lambda w: self.run_sys_async(["foot", "-e", "htop"])
        )
        content_vbox.pack_start(info_btn, True, True, 0)

        info_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        info_btn.add(info_vbox)

        # ---- 1. CPU 监控行 (标签 + 实时条状图) ----
        cpu_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        self.cpu_label = Gtk.Label(label="cpu: --%")
        self.cpu_label.set_halign(Gtk.Align.START)
        self.cpu_label.get_style_context().add_class("hud-title")
        # 固定的文本宽度，防止百分比抖动影响进度条长度
        self.cpu_label.set_size_request(65, -1)

        self.cpu_bar = Gtk.LevelBar()
        self.cpu_bar.set_min_value(0.0)
        self.cpu_bar.set_max_value(1.0)
        self.cpu_bar.get_style_context().add_class("hud-bar")

        cpu_hbox.pack_start(self.cpu_label, False, False, 0)
        cpu_hbox.pack_start(self.cpu_bar, True, True, 0)
        info_vbox.pack_start(cpu_hbox, False, False, 0)

        # ---- 2. 内存 监控行 (标签 + 实时条状图) ----
        mem_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        self.mem_label = Gtk.Label(label="mem: --%")
        self.mem_label.set_halign(Gtk.Align.START)
        self.mem_label.get_style_context().add_class("hud-artist")
        self.mem_label.set_size_request(65, -1)

        self.mem_bar = Gtk.LevelBar()
        self.mem_bar.set_min_value(0.0)
        self.mem_bar.set_max_value(1.0)
        self.mem_bar.get_style_context().add_class("hud-bar")

        mem_hbox.pack_start(self.mem_label, False, False, 0)
        mem_hbox.pack_start(self.mem_bar, True, True, 0)
        info_vbox.pack_start(mem_hbox, False, False, 0)

        # ---- 核心焦点关闭绑定 ----
        self.connect("key-press-event", self.on_key_press)
        self.connect("focus-out-event", lambda w, e: self.close_program())

        self.apply_css()

        # 启动后台异步数据采集监听线程
        threading.Thread(target=self.system_status_loop, daemon=True).start()

    def apply_css(self):
        css = """
        window { background-color: transparent; }
        
        /* 主面板深邃极简质感 - 透明度 0.85 */
        .hud-panel {
            background-color: rgba(22, 22, 22, 0.85);
            border-radius: 20px;
            border: 1px solid rgba(255, 255, 255, 0.05);
            box-shadow: none;
            min-width: 380px;
        }
        
        /* 顶部可点击资源区按钮的隐形化底层 */
        .info-area {
            background-image: none;
            background-color: transparent;
            border: none;
            box-shadow: none;
            text-shadow: none;
            padding: 0px;
        }
        
        .hud-title { 
            color: #FFFFFF; 
            font-size: 13px; 
            font-weight: 600; 
            font-family: "JetBrains Mono", "SF Pro Text", monospace;
        }
        .hud-artist { 
            color: #8C929D; 
            font-size: 13px; 
            font-weight: 600;
            font-family: "JetBrains Mono", "SF Pro Text", monospace;
        }

        /* 原生 LevelBar 条状图深度美化 */
        levelbar.hud-bar {
            -GtkLevelBar-min-block-width: 1;
            -GtkLevelBar-min-block-height: 5;
            background: transparent;
        }
        /* 进度条槽底色槽 */
        levelbar.hud-bar trough {
            padding: 0px;
            background-color: rgba(255, 255, 255, 0.06);
            border-radius: 4px;
            border: none;
        }
        /* 填充后的实时颜色块 */
        levelbar.hud-bar block.filled {
            border: none;
            border-radius: 4px;
            background-color: #81A1C1;
            box-shadow: none;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

    # ---- 系统底层数据流解析 ----
    def run_sys_async(self, args):
        threading.Thread(target=lambda: subprocess.run(args), daemon=True).start()

    def get_cpu_usage(self):
        try:
            with open("/proc/stat", "r") as f:
                line = f.readline()
            parts = list(map(int, line.split()[1:5]))
            work = sum(parts[:3])
            total = sum(parts)
            diff_work = work - self.last_cpu_work
            diff_total = total - self.last_cpu_total
            self.last_cpu_work = work
            self.last_cpu_total = total
            return (diff_work / diff_total) if diff_total != 0 else 0.0
        except Exception:
            return 0.0

    def get_mem_usage(self):
        try:
            with open("/proc/meminfo", "r") as f:
                content = f.read()
            total = int(re.search(r"MemTotal:\s+(\d+)", content).group(1))
            avail = int(re.search(r"MemAvailable:\s+(\d+)", content).group(1))
            return (total - avail) / total
        except Exception:
            return 0.0

    # ---- 核心多线程轮询机制 ----
    def system_status_loop(self):
        while self.is_running:
            cpu_val = self.get_cpu_usage()
            mem_val = self.get_mem_usage()

            GLib.idle_add(self.refresh_ui, cpu_val, mem_val)
            time.sleep(0.5)

    # ---- UI 线程平滑渲染刷新 ----
    def refresh_ui(self, cpu, mem):
        if not self.is_running:
            return

        # 刷新文字标签
        self.cpu_label.set_text(f"cpu: {int(cpu * 100)}%")
        self.mem_label.set_text(f"mem: {int(mem * 100)}%")

        # 动态驱动条状图
        self.cpu_bar.set_value(cpu)
        self.mem_bar.set_value(mem)

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_program()

    def close_program(self):
        if self.is_running:
            self.is_running = False
            self.destroy()
            Gtk.main_quit()
        return False


if __name__ == "__main__":
    win = SystemHudCenter()
    win.connect("destroy", lambda w: win.close_program())
    win.show_all()
    Gtk.main()

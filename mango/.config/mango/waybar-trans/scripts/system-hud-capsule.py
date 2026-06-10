#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：system-hud-circular.py
# Description：高颜值环形仪表盘系统看板（自适应超紧凑版、Cairo 原生硬件加速、透明度 0.85）

import math
import re
import subprocess
import threading
import time

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, GLib, Gtk

try:
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import GtkLayerShell

    HAS_LAYER_SHELL = True
except (ValueError, ImportError):
    HAS_LAYER_SHELL = False


class CircularGauge(Gtk.DrawingArea):
    """使用 Cairo 引擎纯手工绘制的高性能轻量化环形进度条"""

    def __init__(self, fg_color=(0.505, 0.631, 0.757)):  # 默认 Nord 蓝 (#81A1C1)
        super().__init__()
        self.value = 0.0  # 当前进度值 (0.0 ~ 1.0)
        self.fg_color = fg_color
        # 显式设置组件的最小像素尺寸 (宽, 高)
        self.set_size_request(60, 60)
        self.connect("draw", self.on_draw)

    def set_value(self, val):
        self.value = max(0.0, min(1.0, val))
        self.queue_draw()  # 提示 GTK 刷新画布重新绘制

    def on_draw(self, widget, ctx):
        allocation = widget.get_allocation()
        width = allocation.width
        height = allocation.height

        # 计算圆心和半径
        cx = width / 2.0
        cy = height / 2.0
        radius = min(width, height) / 2.0 - 4.0  # 预留 4px 边距防止线条被裁切
        line_width = 5.0  # 圆环线条粗细

        # 统一设置线条样式为圆润平滑
        ctx.set_line_width(line_width)
        ctx.set_line_cap(1)  # Cairo.LineCap.ROUND (圆头圆弧)

        # 1. 绘制背景槽 (暗色半透明环)
        ctx.arc(cx, cy, radius, 0, 2 * math.pi)
        ctx.set_source_rgba(255 / 255, 255 / 255, 255 / 255, 0.06)
        ctx.stroke()

        # 2. 绘制实时进度环 (从正上方 -90° 开始顺时针旋转)
        if self.value > 0:
            start_angle = -math.pi / 2.0
            end_angle = start_angle + (self.value * 2 * math.pi)

            ctx.arc(cx, cy, radius, start_angle, end_angle)
            ctx.set_source_rgb(self.fg_color[0], self.fg_color[1], self.fg_color[2])
            ctx.stroke()


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

        # 主面板盒子（外层完全自适应大小，保持 385px 右侧避让空间）
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        main_vbox.set_halign(Gtk.Align.END)  # 靠右对其收紧
        main_vbox.set_margin_top(1)
        main_vbox.set_margin_bottom(15)
        main_vbox.set_margin_start(15)
        main_vbox.set_margin_end(385)  # 保持纵向完美贴合
        main_vbox.get_style_context().add_class("hud-panel")
        self.add(main_vbox)

        # ==========================================
        # 左右分栏核心交互按钮（点击唤出 foot -e htop）
        # ==========================================
        info_btn = Gtk.Button()
        info_btn.get_style_context().add_class("info-area")
        info_btn.connect(
            "clicked", lambda w: self.run_sys_async(["foot", "-e", "htop"])
        )
        main_vbox.pack_start(info_btn, False, False, 0)

        # 按钮内部的水平布局（自适应宽度，左右间距缩减，完美包裹图表）
        hbox_layout = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        hbox_layout.set_halign(Gtk.Align.CENTER)
        hbox_layout.set_margin_start(16)
        hbox_layout.set_margin_end(16)
        hbox_layout.set_margin_top(12)
        hbox_layout.set_margin_bottom(12)
        info_btn.add(hbox_layout)

        # ---- [左半部分：CPU 环形舱] ----
        cpu_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.cpu_gauge = CircularGauge(fg_color=(0.505, 0.631, 0.757))  # 优雅蓝
        self.cpu_label = Gtk.Label(label="cpu: --%")
        self.cpu_label.get_style_context().add_class("hud-text")
        cpu_vbox.pack_start(self.cpu_gauge, False, False, 0)
        cpu_vbox.pack_start(self.cpu_label, False, False, 0)
        hbox_layout.pack_start(cpu_vbox, False, False, 0)

        # ---- [右半部分：MEM 环形舱] ----
        mem_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.mem_gauge = CircularGauge(fg_color=(0.549, 0.647, 0.525))  # 极简青绿
        self.mem_label = Gtk.Label(label="mem: --%")
        self.mem_label.get_style_context().add_class("hud-text")
        mem_vbox.pack_start(self.mem_gauge, False, False, 0)
        mem_vbox.pack_start(self.mem_label, False, False, 0)
        hbox_layout.pack_start(mem_vbox, False, False, 0)

        # ---- 核心焦点关闭绑定 ----
        self.connect("key-press-event", self.on_key_press)
        self.connect("focus-out-event", lambda w, e: self.close_program())

        self.apply_css()

        # 启动后台异步数据采集监听线程
        threading.Thread(target=self.system_status_loop, daemon=True).start()

    def apply_css(self):
        css = """
        window { background-color: transparent; }
        
        /* 主面板深邃极简质感 - 删除了 min-width，外壳完美贴合内部组件 */
        .hud-panel {
            background-color: rgba(22, 22, 22, 0.85);
            border-radius: 16px;
            border: 1px solid rgba(255, 255, 255, 0.05);
            box-shadow: none;
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
        
        /* 仪表盘下方标签文字的极简主义定义 */
        .hud-text { 
            color: #FFFFFF; 
            font-size: 11px; 
            font-weight: 600; 
            font-family: "JetBrains Mono", "SF Pro Text", monospace;
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

        # 1. 更新文本内容
        self.cpu_label.set_text(f"cpu: {int(cpu * 100)}%")
        self.mem_label.set_text(f"mem: {int(mem * 100)}%")

        # 2. 将数据输入给绘图类，触发 Cairo 引擎无延迟重新绘图
        self.cpu_gauge.set_value(cpu)
        self.mem_gauge.set_value(mem)

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

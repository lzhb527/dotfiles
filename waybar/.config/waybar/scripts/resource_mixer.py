#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：resource_mixer.py
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-25 09:09:12
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
#!/usr/bin/env python3
import glob
import os
import subprocess
import threading

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gdk, GLib, Gtk


class PerAppResourceMixer(Gtk.Window):
    def __init__(self):
        super().__init__(title="Per-App Volume & Resource Mixer")

        # 1. 铺设标志性的全屏暗色半透明大画布
        self.set_decorated(False)
        self.fullscreen()
        self.set_keep_above(True)
        self.set_app_paintable(True)

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and self.is_composited():
            self.set_visual(visual)

        # 2. 核心布局容器
        self.fixed = Gtk.Fixed()
        self.add(self.fixed)

        self.icon_theme = Gtk.IconTheme.get_default()
        self.apps_cache = []

        # 3. 拦截底层的事件与退出锚点
        self.connect("draw", self.on_draw)
        self.connect("configure-event", self.on_window_configured)

        self.add_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.KEY_PRESS_MASK)
        self.connect("button-press-event", lambda w, e: True)
        self.connect("key-press-event", self.on_key_press)

        self.apply_css()

        # 4. 异步刷新：扫描内核进程与系统级音频流
        threading.Thread(target=self.scan_system_resources, daemon=True).start()

    def on_draw(self, widget, cr):
        # 极具科技感的深色高纯度磨砂滤镜
        cr.set_source_rgba(13 / 255, 15 / 255, 23 / 255, 0.96)
        cr.paint()
        return False

    def apply_css(self):
        css = """
        button.mixer-card {
            background-color: rgba(26, 27, 38, 0.9);
            border: 2px solid rgba(255, 255, 255, 0.03);
            border-radius: 16px;
            padding: 16px;
        }
        button.mixer-card:hover {
            background-color: rgba(36, 40, 59, 0.95);
            border-color: #bb9af7;
        }
        label.app-title {
            color: #7aa2f7;
            font-size: 16px;
            font-weight: bold;
        }
        label.slider-title {
            color: #9ece6a;
            font-size: 12px;
        }
        label.slider-title-cpu {
            color: #f7768e;
            font-size: 12px;
        }
        scale highlight {
            background-color: #7aa2f7;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    # ---- 核心控制逻辑：跨桌面数据清洗 ----
    def scan_system_resources(self):
        detected_apps = {}
        # 我们重点锁定的多媒体/高负载图形大类进程
        target_apps = [
            "firefox",
            "chrome",
            "kitty",
            "alacritty",
            "code",
            "spotify",
            "vlc",
            "steam",
            "discord",
        ]

        try:
            # 1. 内核扫雷：通过 procfs 拿到 PID 和名字
            for pid_dir in glob.glob("/proc/[0-9]*"):
                try:
                    pid = os.path.basename(pid_dir)
                    comm_path = os.path.join(pid_dir, "comm")
                    if os.path.exists(comm_path):
                        with open(comm_path, "r") as f:
                            proc_name = f.read().strip().lower()

                        if proc_name in target_apps:
                            if proc_name not in detected_apps:
                                # 获取当前的 Nice 值（CPU 优先级，标准范围为 -20 到 19）
                                nice_val = os.getpriority(os.PRIO_PROCESS, int(pid))
                                detected_apps[proc_name] = {
                                    "pid": pid,
                                    "name": proc_name,
                                    "nice": nice_val,
                                    "volume": self.get_app_volume_via_pactl(
                                        proc_name
                                    ),  # 交叉读取音频
                                }
                except (IOError, ValueError, OSError):
                    continue

            # 极致防空：如果没有抓到特定应用，创建一个系统默认的大通道
            if not detected_apps:
                detected_apps["master"] = {
                    "pid": "0",
                    "name": "系统总音频",
                    "nice": 0,
                    "volume": 80,
                }

        except Exception as e:
            print(f"数据采集失败: {e}")
            detected_apps["master"] = {
                "pid": "0",
                "name": "演示安全通道",
                "nice": 0,
                "volume": 50,
            }

        self.apps_cache = sorted(detected_apps.values(), key=lambda x: x["name"])
        GLib.idle_add(self.trigger_render)

    # ---- 核心接口：通过 pactl/pipewire 互锁获取目标音量 ----
    def get_app_volume_via_pactl(self, app_name):
        try:
            # 现代 Linux 系统的 Pipewire 或者 PulseAudio 都可以通过 pactl list sink-inputs 来读取流
            res = subprocess.run(
                ["pactl", "list", "sink-inputs"],
                capture_output=True,
                text=True,
                check=True,
            )
            output = res.stdout

            # 使用简单的文本清洗，找出属于该应用进程名下的 Volume 百分比
            sections = output.split("Sink Input #")
            for section in sections:
                if (
                    app_name in section.lower()
                    or "application.name" in section
                    and app_name in section
                ):
                    for line in section.splitlines():
                        if "Volume:" in line and "%" in line:
                            match = line.split("/")
                            if len(match) > 1:
                                return int(match[1].strip().replace("%", ""))
        except Exception:
            pass
        return 100  # 找不到则默认为最大音量

    # ---- 物理控制：一键改写内核进程Nice值 ----
    def change_cpu_priority(self, pid, val):
        try:
            target_nice = int(val)
            # 调用内核系统指令 renice 改写进程的 CPU 分配比例
            subprocess.Popen(
                ["renice", str(target_nice), "-p", str(pid)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            print(f"进程 {pid} 的 CPU 优先级已重塑为: {target_nice}")
        except Exception as e:
            print(f"优先级重写越权: {e}")

    # ---- 物理控制：一键重塑独立通道音量 ----
    def change_app_volume(self, app_name, val):
        try:
            target_vol = f"{int(val)}%"
            # 1. 查找对应的 Sink Input ID
            res = subprocess.run(
                ["pactl", "list", "sink-inputs"], capture_output=True, text=True
            )
            sections = res.stdout.split("Sink Input #")
            for section in sections:
                if app_name in section.lower():
                    first_line = section.splitlines()[0].strip()
                    sink_input_id = first_line.split()[0] if first_line else None
                    if sink_input_id and sink_input_id.isdigit():
                        # 通过统一的音频控制流强行注入增益
                        subprocess.Popen(
                            [
                                "pactl",
                                "set-sink-input-volume",
                                sink_input_id,
                                target_vol,
                            ]
                        )
        except Exception as e:
            print(f"音量控制流中断: {e}")

    # ---- 动态网格控制渲染层 ----
    def on_window_configured(self, widget, event):
        self.trigger_render()
        return False

    def trigger_render(self):
        if not self.apps_cache:
            return

        for child in self.fixed.get_children():
            self.fixed.remove(child)

        win_w = self.get_allocated_width()
        win_h = self.get_allocated_height()

        n = len(self.apps_cache)
        cols = 3 if n > 4 else 2
        rows = (n + cols - 1) // cols

        card_w, card_h = 360, 240
        spacing_x, spacing_y = 30, 30

        total_w = cols * card_w + (cols - 1) * spacing_x
        total_h = rows * card_h + (rows - 1) * spacing_y

        start_x = (win_w - total_w) // 2
        start_y = (win_h - total_h) // 2

        for idx, app in enumerate(self.apps_cache):
            r = idx // cols
            c = idx % cols
            x = start_x + c * (card_w + spacing_x)
            y = start_y + r * (card_h + spacing_y)

            card_btn = Gtk.Button()
            card_btn.set_size_request(card_w, card_h)
            card_btn.get_style_context().add_class("mixer-card")

            main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
            card_btn.add(main_vbox)

            # 顶部标题栏：图标 + 应用名 (PID)
            header_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            main_vbox.pack_start(header_hbox, False, False, 0)

            img = Gtk.Image()
            if self.icon_theme.has_icon(app["name"]):
                img.set_from_pixbuf(self.icon_theme.load_icon(app["name"], 24, 0))
            else:
                img.set_from_icon_name("audio-card", Gtk.IconSize.LARGE_TOOLBAR)
            header_hbox.pack_start(img, False, False, 0)

            title_lbl = Gtk.Label(label=f"{app['name'].upper()}  (PID: {app['pid']})")
            title_lbl.get_style_context().add_class("app-title")
            title_lbl.set_halign(Gtk.Align.START)
            header_hbox.pack_start(title_lbl, True, True, 0)

            main_vbox.pack_start(
                Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL), False, False, 2
            )

            # --- 控制核心：1. 独立音量混音滑动条 ---
            vol_lbl = Gtk.Label(label="🔊 独立音量衰减 (Volume Mixer)")
            vol_lbl.get_style_context().add_class("slider-title")
            vol_lbl.set_halign(Gtk.Align.START)
            main_vbox.pack_start(vol_lbl, False, False, 0)

            vol_adj = Gtk.Adjustment(
                value=app["volume"],
                lower=0,
                upper=150,
                step_increment=1,
                page_increment=10,
            )
            vol_scale = Gtk.Scale(
                orientation=Gtk.Orientation.HORIZONTAL, adjustment=vol_adj
            )
            vol_scale.set_value_pos(Gtk.PositionType.RIGHT)
            vol_scale.connect(
                "value-changed",
                lambda s, name=app["name"]: self.change_app_volume(name, s.get_value()),
            )
            main_vbox.pack_start(vol_scale, False, False, 0)

            # --- 控制核心：2. CPU 硬件资源Nice调节条 ---
            cpu_lbl = Gtk.Label(label="🧠 硬件优先级阻尼 (CPU Nice Rate)")
            cpu_lbl.get_style_context().add_class("slider-title-cpu")
            cpu_lbl.set_halign(Gtk.Align.START)
            main_vbox.pack_start(cpu_lbl, False, False, 0)

            # Nice 值 19 代表最低优先级（老实礼让），-20 代表极速响应（强行霸占）
            cpu_adj = Gtk.Adjustment(
                value=app["nice"],
                lower=-20,
                upper=19,
                step_increment=1,
                page_increment=5,
            )
            cpu_scale = Gtk.Scale(
                orientation=Gtk.Orientation.HORIZONTAL, adjustment=cpu_adj
            )
            cpu_scale.set_value_pos(Gtk.PositionType.RIGHT)
            # 在滑动条下方打上易读刻度说明
            cpu_scale.add_mark(
                value=-20,
                position=Gtk.PositionType.BOTTOM,
                markup="<small>强悍</small>",
            )
            cpu_scale.add_mark(
                value=0, position=Gtk.PositionType.BOTTOM, markup="<small>正常</small>"
            )
            cpu_scale.add_mark(
                value=19, position=Gtk.PositionType.BOTTOM, markup="<small>让步</small>"
            )

            cpu_scale.connect(
                "value-changed",
                lambda s, pid=app["pid"]: self.change_cpu_priority(pid, s.get_value()),
            )
            main_vbox.pack_start(cpu_scale, False, False, 0)

            self.fixed.put(card_btn, x, y)

        self.fixed.show_all()

    def on_key_press(self, widget, event):
        # 按下 Esc 键秒级无痕退出整个半透明控制幕布
        if event.keyval == Gdk.KEY_Escape:
            self.destroy()
            Gtk.main_quit()
            return True
        return False


if __name__ == "__main__":
    win = PerAppResourceMixer()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

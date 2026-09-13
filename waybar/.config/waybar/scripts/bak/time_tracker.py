#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：time_tracker.py
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-25 09:17:40
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
import glob
import os
import threading
import time

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gdk, GLib, Gtk


class AutomatedTimeTracker(Gtk.Window):
    def __init__(self):
        super().__init__(title="Automated Kinetic Time Tracker")

        # 1. 建立标志性的全屏暗色科技感幕布
        self.set_decorated(False)
        self.fullscreen()
        self.set_keep_above(True)
        self.set_app_paintable(True)

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and self.is_composited():
            self.set_visual(visual)

        # 2. 核心画布
        self.fixed = Gtk.Fixed()
        self.add(self.fixed)

        self.icon_theme = Gtk.IconTheme.get_default()

        # 3. 生产力数据库模型（累计秒数，以及上一秒的内核 CPU 时间戳）
        # 格式: {"process_name": {"total_time": 秒, "last_cpu_ticks": 总滴答数, "activity_slope": 活跃斜率}}
        self.stats_db = {
            "code": {
                "display_name": "开发编码 (VS Code)",
                "total_time": 0,
                "last_cpu_ticks": 0,
                "activity_slope": 0,
            },
            "firefox": {
                "display_name": "网络调研 (Firefox)",
                "total_time": 0,
                "last_cpu_ticks": 0,
                "activity_slope": 0,
            },
            "chrome": {
                "display_name": "前端调试 (Chrome)",
                "total_time": 0,
                "last_cpu_ticks": 0,
                "activity_slope": 0,
            },
            "kitty": {
                "display_name": "终端矩阵 (Kitty)",
                "total_time": 0,
                "last_cpu_ticks": 0,
                "activity_slope": 0,
            },
            "alacritty": {
                "display_name": "终端矩阵 (Alacritty)",
                "total_time": 0,
                "last_cpu_ticks": 0,
                "activity_slope": 0,
            },
            "obsidian": {
                "display_name": "知识沉淀 (Obsidian)",
                "total_time": 0,
                "last_cpu_ticks": 0,
                "activity_slope": 0,
            },
            "spotify": {
                "display_name": "心流音乐 (Spotify)",
                "total_time": 0,
                "last_cpu_ticks": 0,
                "activity_slope": 0,
            },
        }

        # 4. 事件拦截
        self.connect("draw", self.on_draw)
        self.connect("configure-event", self.on_window_configured)
        self.add_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.KEY_PRESS_MASK)
        self.connect("button-press-event", lambda w, e: True)
        self.connect("key-press-event", self.on_key_press)

        self.apply_css()

        # 5. 启动内核级无感时间守护流 (守护进程)
        self.is_tracking = True
        threading.Thread(target=self.kernel_time_daemon, daemon=True).start()

    def on_draw(self, widget, cr):
        # 深邃黑曜石风格底色
        cr.set_source_rgba(11 / 255, 12 / 255, 18 / 255, 0.95)
        cr.paint()
        return False

    def apply_css(self):
        css = """
        label.dashboard-title {
            color: #ff9e64;
            font-size: 22px;
            font-weight: bold;
            letter-spacing: 3px;
        }
        box.tracker-card {
            background-color: rgba(26, 27, 38, 0.85);
            border: 2px solid rgba(255, 255, 255, 0.03);
            border-radius: 14px;
            padding: 20px;
        }
        label.app-title {
            color: #7aa2f7;
            font-size: 15px;
            font-weight: bold;
        }
        label.time-display {
            color: #73daca;
            font-size: 24px;
            font-weight: bold;
            font-family: monospace;
        }
        label.slope-display {
            font-size: 11px;
            font-weight: bold;
        }
        label.slope-active { color: #f7768e; }
        label.slope-idle { color: #565f89; }
        
        progressbar progress {
            background-color: #73daca;
            border-radius: 4px;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    # ---- 数据采集模块：内核 ticks 差分分析法 ----
    def kernel_time_daemon(self):
        while self.is_tracking:
            try:
                # 临时存储当前秒内各目标进程的总 ticks
                current_ticks_snapshot = {k: 0 for k in self.stats_db.keys()}

                # 扫描整个 Linux 内核 PID 树
                for pid_dir in glob.glob("/proc/[0-9]*"):
                    try:
                        comm_path = os.path.join(pid_dir, "comm")
                        if os.path.exists(comm_path):
                            with open(comm_path, "r") as f:
                                proc_name = f.read().strip().lower()

                            # 如果是目标审计应用
                            if proc_name in current_ticks_snapshot:
                                stat_path = os.path.join(pid_dir, "stat")
                                if os.path.exists(stat_path):
                                    with open(stat_path, "r") as f_stat:
                                        stat_tokens = f_stat.read().split()
                                        # Linux 内核 stat 第14和15位分别是 utime (用户态) 和 stime (内核态)
                                        # 它们代表了该进程自启动以来消耗的 CPU 总时间片
                                        utime = int(stat_tokens[13])
                                        stime = int(stat_tokens[14])
                                        current_ticks_snapshot[proc_name] += (
                                            utime + stime
                                        )
                    except (IOError, IndexError, ValueError):
                        continue

                # 差分算法清洗：计算一秒内谁的 ticks 跳动最为剧烈
                for app, total_ticks in current_ticks_snapshot.items():
                    db_item = self.stats_db[app]

                    if db_item["last_cpu_ticks"] > 0:
                        # 计算当前秒与上一秒的硬件时间增量 (差分结果)
                        delta = total_ticks - db_item["last_cpu_ticks"]
                        db_item["activity_slope"] = delta

                        # 【核心多路对齐过滤】：
                        # 如果一秒内 CPU 增量大于 5 个 ticks，说明用户绝对正在强频交互该软件
                        # 将其判定为“当前的生产力核心”，其累计工时开始递增
                        if delta > 4:
                            db_item["total_time"] += 1

                    # 迭代滚动时间截
                    db_item["last_cpu_ticks"] = total_ticks

            except Exception as e:
                print(f"守护进程快照异常: {e}")

            # 严格一秒钟更新一次主界面
            GLib.idle_add(self.trigger_render)
            time.sleep(1)

    # ---- 动态网格控制渲染层 ----
    def on_window_configured(self, widget, event):
        self.trigger_render()
        return False

    def trigger_render(self):
        for child in self.fixed.get_children():
            self.fixed.remove(child)

        win_w = self.get_allocated_width()
        win_h = self.get_allocated_height()

        # 顶部全局大标题
        title_lbl = Gtk.Label(label="📊 🟢 实时内核级生产力工时分析仓")
        title_lbl.get_style_context().add_class("dashboard-title")
        self.fixed.put(title_lbl, (win_w - 400) // 2, win_h // 10)

        # 布局网格矩阵计算
        apps_list = list(self.stats_db.items())
        n = len(apps_list)
        cols = 3 if n > 4 else 2
        rows = (n + cols - 1) // cols

        card_w, card_h = 360, 160
        spacing_x, spacing_y = 40, 35

        total_w = cols * card_w + (cols - 1) * spacing_x
        total_h = rows * card_h + (rows - 1) * spacing_y

        start_x = (win_w - total_w) // 2
        start_y = win_h // 4 + 20

        for idx, (app_name, data) in enumerate(apps_list):
            r = idx // cols
            c = idx % cols
            x = start_x + c * (card_w + spacing_x)
            y = start_y + r * (card_h + spacing_y)

            # 采用 Gtk.Box 充当不可点击的纯监控卡片
            card_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
            card_box.set_size_request(card_w, card_h)
            card_box.get_style_context().add_class("tracker-card")

            # 1. 头部布局：图标 + 应用名
            header_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            card_box.pack_start(header_hbox, False, False, 0)

            img = Gtk.Image()
            if self.icon_theme.has_icon(app_name):
                img.set_from_pixbuf(self.icon_theme.load_icon(app_name, 22, 0))
            else:
                img.set_from_icon_name("office-calendar", Gtk.IconSize.LARGE_TOOLBAR)
            header_hbox.pack_start(img, False, False, 0)

            app_lbl = Gtk.Label(label=data["display_name"])
            app_lbl.get_style_context().add_class("app-title")
            app_lbl.set_halign(Gtk.Align.START)
            header_hbox.pack_start(app_lbl, True, True, 0)

            # 2. 中部核心：优雅的时间转换显示 (HH:MM:SS)
            seconds = data["total_time"]
            time_str = (
                f"{seconds // 3600:02d}:{(seconds % 3600) // 60:02d}:{seconds % 60:02d}"
            )

            time_lbl = Gtk.Label(label=time_str)
            time_lbl.get_style_context().add_class("time-display")
            time_lbl.set_halign(Gtk.Align.START)
            card_box.pack_start(time_lbl, False, False, 4)

            # 3. 底部状态：实时内核增量斜率指示器
            slope_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            card_box.pack_start(slope_hbox, False, False, 0)

            slope_val = data["activity_slope"]
            if slope_val > 4:
                status_txt = f"⚡ 正在交互 (内核斜率: +{slope_val} 💥)"
                slope_lbl = Gtk.Label(label=status_txt)
                slope_lbl.get_style_context().add_class("slope-active")
            else:
                slope_lbl = Gtk.Label(label="💤 静止挂起 (Dormant)")
                slope_lbl.get_style_context().add_class("slope-idle")

            slope_lbl.set_halign(Gtk.Align.START)
            slope_hbox.pack_start(slope_lbl, True, True, 0)

            # 4. 进度视觉槽（模拟本日任务饱满度）
            pbar = Gtk.ProgressBar()
            # 满格为 1 小时 (3600秒)，动态计算比例
            pbar.set_fraction(min(seconds / 3600.0, 1.0))
            card_box.pack_start(pbar, False, False, 2)

            self.fixed.put(card_box, x, y)

        self.fixed.show_all()

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            # 优雅注销后台守护，防止线程泄露
            self.is_tracking = False
            self.destroy()
            Gtk.main_quit()
            return True
        return False


if __name__ == "__main__":
    win = AutomatedTimeTracker()
    win.connect("destroy", lambda w: Gtk.main_quit())
    win.show_all()
    Gtk.main()

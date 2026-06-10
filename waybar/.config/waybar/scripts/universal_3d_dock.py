#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：universal_3d_dock.py
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-25 09:13:27
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


class Universal3DDock(Gtk.Window):
    def __init__(self):
        super().__init__(title="Universal 3D Topology Dock")

        # 1. 铺设科技感全屏遮罩画布
        self.set_decorated(False)
        self.fullscreen()
        self.set_keep_above(True)
        self.set_app_paintable(True)

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and self.is_composited():
            self.set_visual(visual)

        # 2. 核心三维网格容器
        self.fixed = Gtk.Fixed()
        self.add(self.fixed)

        self.icon_theme = Gtk.IconTheme.get_default()

        # 3. 定义 X轴 (三维矩阵的品类象限)
        self.dock_matrix = {
            "DEVELOPMENT 💻": [
                {"app_id": "code", "display_name": "VS Code"},
                {"app_id": "kitty", "display_name": "Kitty Terminal"},
                {"app_id": "alacritty", "display_name": "Alacritty"},
            ],
            "BROWSER & WEB 🌐": [
                {"app_id": "firefox", "display_name": "Firefox"},
                {"app_id": "google-chrome", "display_name": "Chrome"},
            ],
            "PRODUCTIVITY 📝": [
                {"app_id": "obsidian", "display_name": "Obsidian"},
                {"app_id": "thunderbird", "display_name": "Mail client"},
            ],
            "MEDIA & SYSTEM ⚙️": [
                {"app_id": "spotify", "display_name": "Spotify"},
                {"app_id": "vlc", "display_name": "VLC Player"},
                {"app_id": "thunar", "display_name": "File Manager"},
            ],
        }

        self.active_pids = {}

        # 4. 拦截底层键盘鼠标事件
        self.connect("draw", self.on_draw)
        self.connect("configure-event", self.on_window_configured)
        self.add_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.KEY_PRESS_MASK)
        self.connect("button-press-event", lambda w, e: True)
        self.connect("key-press-event", self.on_key_press)

        self.apply_css()

        # 5. 启动异步流
        threading.Thread(target=self.scan_kernel_processes, daemon=True).start()

    def on_draw(self, widget, cr):
        cr.set_source_rgba(10 / 255, 12 / 255, 22 / 255, 0.94)
        cr.paint()
        return False

    def apply_css(self):
        # 修复核心：移除了导致报错的 transform 属性
        # 改用更符合 GTK3 规范的 border 颜色加深与 background 亮度跨度来模拟三维突起
        css = """
        label.category-hdr {
            color: #ff9e64;
            font-size: 14px;
            font-weight: bold;
            letter-spacing: 2px;
        }
        button.dock-node {
            background-color: rgba(30, 32, 48, 0.5);
            border: 2px solid rgba(255, 255, 255, 0.02);
            border-radius: 12px;
            padding: 15px;
        }
        button.dock-node.alive {
            background-color: rgba(36, 40, 59, 0.9);
            border-color: #7aa2f7;
        }
        button.dock-node:hover {
            background-color: rgba(54, 60, 92, 0.95);
            border-color: #bb9af7;
        }
        label.app-name {
            color: #c0caf5;
            font-size: 13px;
            font-weight: 500;
        }
        label.status-tag {
            font-size: 10px;
            font-weight: bold;
        }
        label.status-tag.running {
            color: #73daca;
        }
        label.status-tag.dormant {
            color: #565f89;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def scan_kernel_processes(self):
        self.active_pids.clear()
        try:
            for pid_dir in glob.glob("/proc/[0-9]*"):
                try:
                    comm_path = os.path.join(pid_dir, "comm")
                    if os.path.exists(comm_path):
                        with open(comm_path, "r") as f:
                            proc_name = f.read().strip().lower()

                        pid = os.path.basename(pid_dir)
                        if proc_name not in self.active_pids:
                            self.active_pids[proc_name] = []
                        self.active_pids[proc_name].append(pid)
                except (IOError, ValueError):
                    continue
        except Exception as e:
            print(f"内核扫描受阻: {e}")

        GLib.idle_add(self.trigger_render)

    def dispatch_or_launch_app(self, app_id):
        proc_key = "chrome" if "chrome" in app_id else app_id

        if proc_key in self.active_pids and self.active_pids[proc_key]:
            try:
                subprocess.Popen(
                    [app_id], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                )
            except Exception:
                pass
        else:
            try:
                subprocess.Popen(
                    [app_id], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                )
            except Exception as e:
                print(f"启动失败: {e}")

        self.close_dock()

    def on_window_configured(self, widget, event):
        self.trigger_render()
        return False

    def trigger_render(self):
        for child in self.fixed.get_children():
            self.fixed.remove(child)

        win_w = self.get_allocated_width()
        win_h = self.get_allocated_height()

        num_categories = len(self.dock_matrix)
        col_w = 260
        spacing_x = 50
        total_w = num_categories * col_w + (num_categories - 1) * spacing_x
        start_x = (win_w - total_w) // 2
        start_y = win_h // 4

        for col_idx, (category_name, apps) in enumerate(self.dock_matrix.items()):
            current_x = start_x + col_idx * (col_w + spacing_x)

            hdr_lbl = Gtk.Label(label=category_name)
            hdr_lbl.get_style_context().add_class("category-hdr")
            hdr_lbl.set_halign(Gtk.Align.CENTER)
            self.fixed.put(hdr_lbl, current_x + 30, start_y - 40)

            for row_idx, app in enumerate(apps):
                current_y = start_y + row_idx * (85 + 20)

                node_btn = Gtk.Button()
                node_btn.set_size_request(col_w, 85)
                node_btn.get_style_context().add_class("dock-node")

                proc_key = "chrome" if "chrome" in app["app_id"] else app["app_id"]
                is_alive = proc_key in self.active_pids and self.active_pids[proc_key]

                if is_alive:
                    node_btn.get_style_context().add_class("alive")

                inner_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
                node_btn.add(inner_hbox)

                img = Gtk.Image()
                try:
                    if self.icon_theme.has_icon(app["app_id"]):
                        img.set_from_pixbuf(
                            self.icon_theme.load_icon(app["app_id"], 32, 0)
                        )
                    else:
                        img.set_from_icon_name(
                            "application-x-executable", Gtk.IconSize.DND
                        )
                except Exception:
                    img.set_from_icon_name("application-x-executable", Gtk.IconSize.DND)
                inner_hbox.pack_start(img, False, False, 0)

                txt_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
                inner_hbox.pack_start(txt_vbox, True, True, 0)

                name_lbl = Gtk.Label(label=app["display_name"])
                name_lbl.get_style_context().add_class("app-name")
                name_lbl.set_halign(Gtk.Align.START)
                txt_vbox.pack_start(name_lbl, False, False, 0)

                if is_alive:
                    instances = len(self.active_pids[proc_key])
                    status_lbl = Gtk.Label(label=f"● 运行中 ({instances} 实例)")
                    status_lbl.get_style_context().add_class("status-tag")
                    status_lbl.get_style_context().add_class("running")
                else:
                    status_lbl = Gtk.Label(label="○ 已休眠")
                    status_lbl.get_style_context().add_class("status-tag")
                    status_lbl.get_style_context().add_class("dormant")

                status_lbl.set_halign(Gtk.Align.START)
                txt_vbox.pack_start(status_lbl, False, False, 0)

                node_btn.connect(
                    "clicked",
                    lambda b, aid=app["app_id"]: self.dispatch_or_launch_app(aid),
                )
                self.fixed.put(node_btn, current_x, current_y)

        self.fixed.show_all()

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_dock()
            return True
        return False

    def close_dock(self):
        self.destroy()
        Gtk.main_quit()


if __name__ == "__main__":
    win = Universal3DDock()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：app-launcher.py
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-25 08:23:16
# Description：Wayland Layer Shell 完美无边框应用启动器（全屏透明遮罩完美版）
# Copyright (C) 2026  Ltd. All rights reserved.
import os
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


class AppLauncher(Gtk.Window):
    def __init__(self):
        super().__init__(title="App Launcher")

        # ---- Wayland Layer Shell 核心配置 ----
        if HAS_LAYER_SHELL:
            GtkLayerShell.init_for_window(self)
            # 使用 OVERLAY 层确保在最上层
            GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
            # 开启键盘独占模式
            GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.EXCLUSIVE)

            # 🛠️ 【核心改动】上下左右全部拉满！让窗口变成全屏幕大小
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, True)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, True)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        else:
            self.set_decorated(False)
            self.set_keep_above(True)
            self.set_position(Gtk.WindowPosition.CENTER)
            self.set_default_size(550, 450)

        # 强制支持半透明底色（对全屏暗色遮罩至关重要）
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and self.is_composited():
            self.set_visual(visual)

        # 2. 数据存储
        self.all_apps = []
        self.filtered_apps = []
        self.icon_theme = Gtk.IconTheme.get_default()

        # 3. 布局：利用一个全屏的 EventBox 来捕捉点击
        overlay_bg = Gtk.EventBox()
        overlay_bg.connect("button-press-event", self.on_bg_clicked)
        self.add(overlay_bg)

        # 居中对齐容器：让内部的 Launcher 面板待在屏幕正中间
        center_align = Gtk.Alignment.new(0.5, 0.5, 0, 0)
        overlay_bg.add(center_align)

        # 真正的 Launcher 主体盒子
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        main_box.set_margin_top(15)
        main_box.set_margin_bottom(15)
        main_box.set_margin_start(15)
        main_box.set_margin_end(15)

        # 给真正的面板赋予特定样式类名，并在 CSS 中单独美化
        main_box.get_style_context().add_class("launcher-panel")

        # 🛠️ 在这里控制你想要的 Launcher 实际大小
        main_box.set_size_request(550, 450)
        center_align.add(main_box)

        # ---- 顶部：搜索输入框 ----
        self.search_entry = Gtk.Entry()
        self.search_entry.set_placeholder_text("🔍 搜索应用...")
        self.search_entry.connect("changed", self.on_search_changed)
        main_box.pack_start(self.search_entry, False, False, 0)

        # ---- 中部：滚动视图 + 列表框 ----
        scroll_win = Gtk.ScrolledWindow()
        scroll_win.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        main_box.pack_start(scroll_win, True, True, 0)

        self.list_box = Gtk.ListBox()
        self.list_box.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.list_box.connect("row-activated", self.on_row_activated)
        scroll_win.add(self.list_box)

        # ---- 底部：快捷键提示 ----
        tip_lbl = Gtk.Label(
            label="💡 提示: [↑/↓] 切换选择 | [Enter] 启动 | [ESC] 或 [点击外部] 退出"
        )
        tip_lbl.set_halign(Gtk.Align.START)
        tip_lbl.get_style_context().add_class("dim-label")
        main_box.pack_start(tip_lbl, False, False, 0)

        # 4. 事件绑定
        self.connect("key-press-event", self.on_key_press)

        # 5. 应用外观美化
        self.apply_css()

        # 6. 后台加载所有已安装的应用数据
        threading.Thread(target=self.load_installed_apps, daemon=True).start()

    def apply_css(self):
        css = """
        /* 全屏背景：这里设置为完全透明。如果你想要暗化背景的蒙版效果，可以改成 rgba(0,0,0,0.4) */
        window {
            background-color: rgba(0, 0, 0, 0.0); 
        }
        /* 真正的启动器面板样式 */
        .launcher-panel {
            background-color: rgba(36, 40, 59, 0.96);
            border-radius: 12px;
            border: 1px solid rgba(255, 255, 255, 0.08);
        }
        entry {
            background-color: #1a1b26;
            color: #c0caf5;
            border: 1px solid #3b4261;
            border-radius: 8px;
            font-size: 16px;
            padding: 10px;
        }
        entry:focus {
            border-color: #7aa2f7;
        }
        listrow {
            padding: 8px 12px;
            border-radius: 6px;
            background-color: transparent;
        }
        listrow:selected {
            background-color: #3b4261;
        }
        label {
            color: #a9b1d6;
            font-size: 14px;
        }
        label.app-title {
            color: #c0caf5;
            font-weight: bold;
            font-size: 15px;
        }
        .dim-label {
            font-size: 11px;
            color: #565f89;
            margin-top: 5px;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    # ---- 完美的点击外部判定 ----
    def on_bg_clicked(self, widget, event):
        """由于 EventBox 铺满了全屏，只要点到它，说明绝对点在面板外面了"""
        self.close_launcher()
        return True

    # ---- 数据采集：解析 Linux 的 .desktop 文件 ----
    def load_installed_apps(self):
        apps_dirs = [
            "/usr/share/applications/",
            os.path.expanduser("~/.local/share/applications/"),
        ]
        seen_names = set()
        temp_apps = []

        for d in apps_dirs:
            if not os.path.exists(d):
                continue
            for file in os.listdir(d):
                if not file.endswith(".desktop"):
                    continue
                try:
                    full_path = os.path.join(d, file)
                    name, exec_cmd, icon = None, None, None
                    no_display = False

                    with open(full_path, "r", errors="ignore") as f:
                        for line in f:
                            if line.startswith("Name="):
                                name = line.split("=", 1)[1].strip()
                            elif line.startswith("Exec="):
                                exec_cmd = line.split("=", 1)[1].split("%")[0].strip()
                            elif line.startswith("Icon="):
                                icon = line.split("=", 1)[1].strip()
                            elif line.startswith("NoDisplay=true"):
                                no_display = True

                    if name and exec_cmd and not no_display:
                        if name not in seen_names:
                            seen_names.add(name)
                            temp_apps.append(
                                {"name": name, "exec": exec_cmd, "icon": icon}
                            )
                except Exception:
                    continue

        self.all_apps = sorted(temp_apps, key=lambda x: x["name"].lower())
        self.filtered_apps = self.all_apps.copy()

        GLib.idle_add(self.refresh_list_view)

    def refresh_list_view(self):
        for child in self.list_box.get_children():
            self.list_box.remove(child)

        for app in self.filtered_apps:
            row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)

            img = Gtk.Image()
            if app["icon"]:
                try:
                    if self.icon_theme.has_icon(app["icon"]):
                        pixbuf = self.icon_theme.load_icon(app["icon"], 32, 0)
                        img.set_from_pixbuf(pixbuf)
                    elif os.path.exists(app["icon"]):
                        pixbuf = Gdk.Pixbuf.new_from_file_at_scale(
                            app["icon"], 32, 32, True
                        )
                        img.set_from_pixbuf(pixbuf)
                    else:
                        img.set_from_icon_name(
                            "application-x-executable", Gtk.IconSize.DND
                        )
                except Exception:
                    img.set_from_icon_name("application-x-executable", Gtk.IconSize.DND)
            else:
                img.set_from_icon_name("application-x-executable", Gtk.IconSize.DND)

            row_box.pack_start(img, False, False, 0)

            lbl = Gtk.Label(label=app["name"])
            lbl.get_style_context().add_class("app-title")
            lbl.set_halign(Gtk.Align.START)
            row_box.pack_start(lbl, True, True, 0)

            self.list_box.add(row_box)

        self.list_box.show_all()

        first_row = self.list_box.get_row_at_index(0)
        if first_row:
            self.list_box.select_row(first_row)

    # ---- 搜索过滤算法 ----
    def on_search_changed(self, entry):
        text = entry.get_text().strip().lower()
        if not text:
            self.filtered_apps = self.all_apps.copy()
        else:
            self.filtered_apps = [
                app for app in self.all_apps if text in app["name"].lower()
            ]

        self.refresh_list_view()

    # ---- 反向控制：启动软件 ----
    def on_row_activated(self, list_box, row):
        idx = row.get_index()
        if 0 <= idx < len(self.filtered_apps):
            app = self.filtered_apps[idx]
            try:
                subprocess.Popen(
                    app["exec"].split(),
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            except Exception as e:
                print(f"启动失败: {e}")

        self.close_launcher()

    # ---- 键盘交互动作 ----
    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_launcher()
            return True

        elif event.keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            selected_row = self.list_box.get_selected_row()
            if selected_row:
                self.on_row_activated(self.list_box, selected_row)
            return True

        elif event.keyval == Gdk.KEY_Up:
            selected_row = self.list_box.get_selected_row()
            if selected_row:
                idx = selected_row.get_index()
                prev_row = self.list_box.get_row_at_index(idx - 1)
                if prev_row:
                    self.list_box.select_row(prev_row)
                    prev_row.grab_focus()
                    self.search_entry.grab_focus()
            return True

        elif event.keyval == Gdk.KEY_Down:
            selected_row = self.list_box.get_selected_row()
            if selected_row:
                idx = selected_row.get_index()
                next_row = self.list_box.get_row_at_index(idx + 1)
                if next_row:
                    self.list_box.select_row(next_row)
                    next_row.grab_focus()
                    self.search_entry.grab_focus()
            return True

        return False

    def close_launcher(self):
        self.destroy()
        Gtk.main_quit()


if __name__ == "__main__":
    win = AppLauncher()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：app-launcher.py
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-25 08:23:16
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
import os
import subprocess
import threading

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gdk, GLib, Gtk


class AppLauncher(Gtk.Window):
    def __init__(self):
        super().__init__(title="App Launcher")

        # 1. 窗口基础设置：完全去掉边框、居中弹出、保持最前
        self.set_decorated(False)
        self.set_default_size(550, 450)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_keep_above(True)

        # 支持半透明底色
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and self.is_composited():
            self.set_visual(visual)

        # 2. 数据存储
        self.all_apps = []  # 存储所有扫描到的原始应用数据
        self.filtered_apps = []  # 存储搜索过滤后的应用数据
        self.icon_theme = Gtk.IconTheme.get_default()

        # 3. 布局：大垂直盒子
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        main_box.set_margin_top(15)
        main_box.set_margin_bottom(15)
        main_box.set_margin_start(15)
        main_box.set_margin_end(15)
        self.add(main_box)

        # ---- 顶部：搜索输入框 ----
        self.search_entry = Gtk.Entry()
        self.search_entry.set_placeholder_text("🔍 搜索应用...")
        self.search_entry.connect("changed", self.on_search_changed)
        main_box.pack_start(self.search_entry, False, False, 0)

        # ---- 中部：滚动视图 + 列表框 ----
        scroll_win = Gtk.ScrolledWindow()
        scroll_win.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        main_box.pack_start(scroll_win, True, True, 0)

        # ListBox 非常适合做这类纵向带高亮选中的列表
        self.list_box = Gtk.ListBox()
        self.list_box.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.list_box.connect("row-activated", self.on_row_activated)
        scroll_win.add(self.list_box)

        # ---- 底部：快捷键提示 ----
        tip_lbl = Gtk.Label(label="💡 提示: [↑/↓] 切换选择 | [Enter] 启动 | [ESC] 退出")
        tip_lbl.set_halign(Gtk.Align.START)
        tip_lbl.get_style_context().add_class("dim-label")
        main_box.pack_start(tip_lbl, False, False, 0)

        # 4. 绑定额外的键盘事件（捕获输入框里的回车和方向键）
        self.connect("key-press-event", self.on_key_press)

        # 5. 应用外观美化
        self.apply_css()

        # 6. 后台加载所有已安装的应用数据
        threading.Thread(target=self.load_installed_apps, daemon=True).start()

    def apply_css(self):
        """赋予其类似 Rofi/Alfred 的现代输入搜索框质感"""
        css = """
        window {
            background-color: rgba(36, 40, 59, 0.96); /* 暗夜蓝半透明 */
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
            border-color: #7aa2f7; /* 聚焦时变为蓝色 */
        }
        listrow {
            padding: 8px 12px;
            border-radius: 6px;
            background-color: transparent;
        }
        listrow:selected {
            background-color: #3b4261; /* 选中行变色 */
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

    # ---- 数据采集：解析 Linux 的 .desktop 文件 ----
    def load_installed_apps(self):
        """扫描 Linux 系统中的快捷方式目录"""
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
                            # 只解析主要段落
                            if line.startswith("Name="):
                                name = line.split("=", 1)[1].strip()
                            elif line.startswith("Exec="):
                                # 清理 Exec 里的参数如 %U, %f
                                exec_cmd = line.split("=", 1)[1].split("%")[0].strip()
                            elif line.startswith("Icon="):
                                icon = line.split("=", 1)[1].strip()
                            elif line.startswith("NoDisplay=true"):
                                no_display = True

                    # 过滤掉系统隐藏组件和无有效执行命令的快捷方式
                    if name and exec_cmd and not no_display:
                        if name not in seen_names:
                            seen_names.add(name)
                            temp_apps.append(
                                {"name": name, "exec": exec_cmd, "icon": icon}
                            )
                except Exception:
                    continue

        # 排序：按字母升序
        self.all_apps = sorted(temp_apps, key=lambda x: x["name"].lower())
        self.filtered_apps = self.all_apps.copy()

        # 安全送回主线程进行第一次列表渲染
        GLib.idle_add(self.refresh_list_view)

    def refresh_list_view(self):
        """将筛选后的数据绘制到界面上"""
        # 清空当前列表
        for child in self.list_box.get_children():
            self.list_box.remove(child)

        # 重新填充
        for app in self.filtered_apps:
            row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)

            # 加载系统图标
            img = Gtk.Image()
            if app["icon"]:
                try:
                    if self.icon_theme.has_icon(app["icon"]):
                        pixbuf = self.icon_theme.load_icon(app["icon"], 32, 0)
                        img.set_from_pixbuf(pixbuf)
                    elif os.path.exists(app["icon"]):  # 有的应用图标写的是绝对路径
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

            # 文字：应用名字
            lbl = Gtk.Label(label=app["name"])
            lbl.get_style_context().add_class("app-title")
            lbl.set_halign(Gtk.Align.START)
            row_box.pack_start(lbl, True, True, 0)

            self.list_box.add(row_box)

        self.list_box.show_all()

        # 默认选中第一项
        first_row = self.list_box.get_row_at_index(0)
        if first_row:
            self.list_box.select_row(first_row)

    # ---- 搜索过滤算法 ----
    def on_search_changed(self, entry):
        """当输入框文字改变时触发模糊过滤"""
        text = entry.get_text().strip().lower()
        if not text:
            self.filtered_apps = self.all_apps.copy()
        else:
            # 简单的模糊包含匹配
            self.filtered_apps = [
                app for app in self.all_apps if text in app["name"].lower()
            ]

        self.refresh_list_view()

    # ---- 反向控制：启动软件 ----
    def on_row_activated(self, list_box, row):
        """激活某一行（点击或回车）时启动应用"""
        idx = row.get_index()
        if 0 <= idx < len(self.filtered_apps):
            app = self.filtered_apps[idx]
            try:
                # 使用 subprocess.Popen 剥离父进程，使其独立在后台运行
                subprocess.Popen(
                    app["exec"].split(),
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            except Exception as e:
                print(f"启动失败: {e}")

        # 启动后自我毁灭关闭
        self.close_launcher()

    # ---- 键盘交互动作 ----
    def on_key_press(self, widget, event):
        """拦截键盘动作，支持纯键盘流操作"""
        if event.keyval == Gdk.KEY_Escape:
            self.close_launcher()
            return True

        # 捕捉回车键：直接激活当前选中的那一行
        elif event.keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            selected_row = self.list_box.get_selected_row()
            if selected_row:
                self.on_row_activated(self.list_box, selected_row)
            return True

        # 捕捉上下方向键：帮输入框代领，在 ListBox 列表里上下移动焦点
        elif event.keyval == Gdk.KEY_Up:
            selected_row = self.list_box.get_selected_row()
            if selected_row:
                idx = selected_row.get_index()
                prev_row = self.list_box.get_row_at_index(idx - 1)
                if prev_row:
                    self.list_box.select_row(prev_row)
                    prev_row.grab_focus()  # 滚动条自动跟进
                    self.search_entry.grab_focus()  # 把焦点还给输入框，确保能连续输入
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

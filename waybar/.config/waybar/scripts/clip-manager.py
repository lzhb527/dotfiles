#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：clip-manager.py
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-25 08:31:38
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
import subprocess
import threading

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gdk, GLib, Gtk


class ClipboardManager(Gtk.Window):
    def __init__(self):
        super().__init__(title="Clipboard Manager")

        # 1. 窗口基础设置：无边框、右侧浮动弹出、置顶
        self.set_decorated(False)
        self.set_default_size(380, 500)
        self.set_keep_above(True)

        # 让它从屏幕右侧弹出（模仿主流剪贴板助手的习惯）
        self.set_position(Gtk.WindowPosition.CENTER)

        # 支持半透明底色
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and self.is_composited():
            self.set_visual(visual)

        # 2. 数据存储
        self.history_items = []  # 存储剪贴板历史原始数据
        self.filtered_items = []  # 存储过滤后的数据

        # 3. 布局：纵向盒子
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        main_box.set_margin_top(15)
        main_box.set_margin_bottom(15)
        main_box.set_margin_start(15)
        main_box.set_margin_end(15)
        self.add(main_box)

        # ---- 顶部：搜索过滤框 ----
        self.search_entry = Gtk.Entry()
        self.search_entry.set_placeholder_text("🔍 搜索历史记录...")
        self.search_entry.connect("changed", self.on_search_changed)
        main_box.pack_start(self.search_entry, False, False, 0)

        # ---- 中部：滚动视图 + 历史列表 ----
        scroll_win = Gtk.ScrolledWindow()
        scroll_win.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        main_box.pack_start(scroll_win, True, True, 0)

        self.list_box = Gtk.ListBox()
        self.list_box.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.list_box.connect("row-activated", self.on_row_activated)
        scroll_win.add(self.list_box)

        # ---- 底部：快捷键与说明 ----
        tip_lbl = Gtk.Label(label="💡 [↑/↓] 选择 | [Enter] 覆盖剪贴板 | [ESC] 退出")
        tip_lbl.set_halign(Gtk.Align.START)
        tip_lbl.get_style_context().add_class("dim-label")
        main_box.pack_start(tip_lbl, False, False, 0)

        # 4. 键盘流联动拦截
        self.connect("key-press-event", self.on_key_press)

        # 5. 注入现代感微光皮肤
        self.apply_css()

        # 6. 后台线程：拉取 cliphist 存储的剪贴板数据
        threading.Thread(target=self.load_clip_history, daemon=True).start()

    def apply_css(self):
        """赋予其高品质浮动面板质感"""
        css = """
        window {
            background-color: rgba(30, 30, 46, 0.96); /* 深紫黑半透明 */
            border-radius: 14px;
            border: 1px solid rgba(255, 255, 255, 0.08);
        }
        entry {
            background-color: #11111b;
            color: #cdd6f4;
            border: 1px solid #45475a;
            border-radius: 8px;
            font-size: 15px;
            padding: 8px 12px;
        }
        entry:focus {
            border-color: #cba6f7; /* 聚焦时呈现柔和紫色 */
        }
        listrow {
            padding: 10px 14px;
            border-radius: 6px;
            margin-bottom: 4px;
            background-color: rgba(255, 255, 255, 0.02);
            border: 1px solid rgba(255, 255, 255, 0.02);
        }
        listrow:hover {
            background-color: rgba(255, 255, 255, 0.05);
        }
        listrow:selected {
            background-color: rgba(203, 166, 247, 0.2); /* 选中的淡紫色背景 */
            border-color: #cba6f7;
        }
        label.clip-text {
            color: #cdd6f4;
            font-size: 13.5px;
        }
        .dim-label {
            font-size: 11px;
            color: #6c7086;
            margin-top: 4px;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    # ---- 数据采集：从 cliphist 提取数据 ----
    def load_clip_history(self):
        """利用 cliphist list 读取所有的剪贴板文本历史"""
        try:
            # cliphist list 会返回编码过的列表，格式如: "0\t第一条内容...", "1\t第二条内容..."
            res = subprocess.run(
                ["cliphist", "list"], capture_output=True, text=True, check=True
            )
            lines = res.stdout.splitlines()

            temp_items = []
            for line in lines:
                if "\t" in line:
                    id_part, text_part = line.split("\t", 1)
                    temp_items.append({"id": id_part, "text": text_part})

            self.history_items = temp_items
            self.filtered_items = self.history_items.copy()

        except Exception as e:
            print(f"读取剪贴板历史失败，请确保后台在运行 cliphist: {e}")
            self.history_items = [
                {"id": "-1", "text": "暂无历史记录（请检查 cliphist 是否运行）"}
            ]
            self.filtered_items = self.history_items.copy()

        # 回归主线程渲染
        GLib.idle_add(self.refresh_list_view)

    def refresh_list_view(self):
        """绘制列表"""
        for child in self.list_box.get_children():
            self.list_box.remove(child)

        for item in self.filtered_items:
            # 剪贴板可能包含巨量长文本，列表里我们只截取前 45 个字符预览
            display_text = item["text"]
            if len(display_text) > 45:
                display_text = display_text[:45].replace("\n", " ") + "..."

            row_lbl = Gtk.Label(label=display_text)
            row_lbl.get_style_context().add_class("clip-text")
            row_lbl.set_halign(Gtk.Align.START)
            row_lbl.set_ellipsize(gi.repository.Pango.EllipsizeMode.END)  # 优雅裁剪

            self.list_box.add(row_lbl)

        self.list_box.show_all()

        # 默认高亮选中最顶部的最新复制记录
        first_row = self.list_box.get_row_at_index(0)
        if first_row:
            self.list_box.select_row(first_row)

    # ---- 搜索过滤算法 ----
    def on_search_changed(self, entry):
        text = entry.get_text().strip().lower()
        if not text:
            self.filtered_items = self.history_items.copy()
        else:
            self.filtered_items = [
                item for item in self.history_items if text in item["text"].lower()
            ]
        self.refresh_list_view()

    # ---- 反向控制：把选中的历史数据推回主剪贴板 ----
    def on_row_activated(self, list_box, row):
        idx = row.get_index()
        if 0 <= idx < len(self.filtered_items):
            item = self.filtered_items[idx]
            if item["id"] != "-1":
                try:
                    # 通过给 cliphist decode 喂入刚才记录的条目 ID，它会自动提取原始的完整文本
                    decode_proc = subprocess.Popen(
                        ["cliphist", "decode", item["id"]], stdout=subprocess.PIPE
                    )
                    # 紧接着把拿到的原始文本通过管道打给 wl-copy，重新写入系统当前剪贴板中！
                    subprocess.run(["wl-copy"], stdin=decode_proc.stdout)
                    print(f"已成功恢复第 [{item['id']}] 条历史记录到系统剪贴板")
                except Exception as e:
                    print(f"写入剪贴板失败: {e}")

        # 完成使命，功成身退
        self.close_manager()

    # ---- 完美的键盘控制交互流 ----
    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_manager()
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

    def close_manager(self):
        self.destroy()
        Gtk.main_quit()


if __name__ == "__main__":
    win = ClipboardManager()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

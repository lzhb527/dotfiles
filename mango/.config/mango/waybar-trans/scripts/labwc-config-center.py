#!/usr/bin/env python3
# -*- coding:utf-8 -*-
"""
Filename：labwc-waybar-config.py
Description：集成 Waybar JSON 配置管理的图形化双栏面板（生产级增强安全版）
"""

import json
import os
import re
import subprocess

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, Gtk

# 实际开发中指向 ~/.config/waybar/config.json
WAYBAR_CONFIG_PATH = os.path.expanduser("~/.config/waybar/config.json")


class ConfigCenter(Gtk.Window):
    def __init__(self):
        super().__init__(title="Linux Wayland Control Center")
        self.set_default_size(850, 550)
        self.set_position(Gtk.WindowPosition.CENTER)

        # 初始化 Waybar JSON 数据
        self.load_waybar_config()

        # 双栏主布局
        main_layout = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        self.add(main_layout)

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)

        self.sidebar = Gtk.StackSidebar()
        self.sidebar.set_stack(self.stack)
        self.sidebar.set_size_request(220, -1)

        main_layout.pack_start(self.sidebar, False, False, 0)
        main_layout.pack_start(self.stack, True, True, 0)

        # --- 载入面板 ---
        self.init_labwc_page()  # Labwc 面板
        self.init_waybar_page()  # Waybar 面板

        self.apply_custom_css()

    def get_default_template(self):
        """返回默认的 Waybar 配置模版"""
        return {
            "position": "top",
            "height": 32,
            "modules-left": ["labwc/workspace", "labwc/mode"],
            "modules-center": ["clock"],
            "modules-right": ["cpu", "memory", "battery", "tray"],
        }

    def _strip_comments(self, text):
        """正则移除 JSONC 中的 // 和 /* */ 注释，防止 json.loads 失败"""
        pattern = r"(([\"'])(?:(?=(\\?))\3.)*?\2)|(?://[^\n]*|/\*(?:[^*]|\*(?!/))*\*/)"
        regex = re.compile(pattern, re.VERBOSE | re.MULTILINE | re.DOTALL)

        def _replacer(match):
            if match.group(1) is not None:
                return match.group(1)
            return ""

        return regex.sub(_replacer, text)

    def load_waybar_config(self):
        """读取 Waybar 的 JSON 配置，增强容错与格式兼容"""
        if os.path.exists(WAYBAR_CONFIG_PATH):
            try:
                with open(WAYBAR_CONFIG_PATH, "r", encoding="utf-8") as f:
                    content = f.read().strip()
                if content:
                    # 剥离注释后再解析
                    clean_content = self._strip_comments(content)
                    parsed_data = json.loads(clean_content)

                    # 如果用户配置是多显示器数组 [{}, {}]，默认取第一个进行编辑
                    if isinstance(parsed_data, list):
                        self.waybar_data = (
                            parsed_data[0]
                            if len(parsed_data) > 0
                            else self.get_default_template()
                        )
                        self.is_array_config = True
                        self.full_raw_array = parsed_data
                    else:
                        self.waybar_data = parsed_data
                        self.is_array_config = False
                    return
            except Exception as e:
                print(f"解析已有 JSON 失败（可能存在复杂语法）: {e}")

        # 回退到默认模板
        self.waybar_data = self.get_default_template()
        self.is_array_config = False

    def show_message_dialog(self, message_type, title, text):
        """通用的 GUI 提示弹窗"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=message_type,
            buttons=Gtk.ButtonsType.OK,
            text=title,
        )
        dialog.format_secondary_text(text)
        dialog.run()
        dialog.destroy()

    def init_waybar_page(self):
        """构建 Waybar 状态栏图形化配置面板"""
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        page.set_margin_top(24)
        page.set_margin_start(32)
        page.set_margin_end(32)
        page.set_margin_bottom(24)

        # 1. 标题
        title = Gtk.Label(label="Waybar 状态栏设置")
        title.get_style_context().add_class("page-title")
        title.set_alignment(0, 0.5)
        page.pack_start(title, False, False, 0)

        # 2. 配置卡片
        card = Gtk.ListBox()
        card.get_style_context().add_class("settings-card")
        card.set_selection_mode(Gtk.SelectionMode.NONE)

        # ---- 配置项 A：位置选择 ----
        row_pos = Gtk.ListBoxRow()
        box_pos = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        box_pos.set_border_width(12)

        lbl_pos = Gtk.Label(label="状态栏屏幕位置 (Position)")
        lbl_pos.get_style_context().add_class("item-label")

        self.combo_pos = Gtk.ComboBoxText()
        positions = ["top", "bottom", "left", "right"]
        for pos in positions:
            self.combo_pos.append_text(pos)

        current_pos = self.waybar_data.get("position", "top")
        if current_pos in positions:
            self.combo_pos.set_active(positions.index(current_pos))
        else:
            self.combo_pos.set_active(0)

        box_pos.pack_start(lbl_pos, True, True, 0)
        box_pos.pack_end(self.combo_pos, False, False, 0)
        row_pos.add(box_pos)
        card.add(row_pos)

        # ---- 配置项 B：高度调整 ----
        row_h = Gtk.ListBoxRow()
        box_h = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        box_h.set_border_width(12)

        lbl_h = Gtk.Label(label="状态栏高度 (Height px)")
        lbl_h.get_style_context().add_class("item-label")

        self.spin_h = Gtk.SpinButton.new_with_range(16, 100, 1)
        # 兼容处理：高度在原配置中可能是字符串 "32"，强转为 float 避免报错
        try:
            val_h = float(self.waybar_data.get("height", 32))
        except ValueError:
            val_h = 32.0
        self.spin_h.set_value(val_h)

        box_h.pack_start(lbl_h, True, True, 0)
        box_h.pack_end(self.spin_h, False, False, 0)
        row_h.add(box_h)
        card.add(row_h)

        # ---- 配置项 C：CPU 模块开关 ----
        row_cpu = Gtk.ListBoxRow()
        box_cpu = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        box_cpu.set_border_width(12)

        lbl_cpu = Gtk.Label(label="显示 CPU 监控模块")
        lbl_cpu.get_style_context().add_class("item-label")

        self.switch_cpu = Gtk.Switch()
        has_cpu = "cpu" in self.waybar_data.get("modules-right", [])
        self.switch_cpu.set_active(has_cpu)

        box_cpu.pack_start(lbl_cpu, True, True, 0)
        box_cpu.pack_end(self.switch_cpu, False, False, 0)
        row_cpu.add(box_cpu)
        card.add(row_cpu)

        page.pack_start(card, False, False, 0)

        # 3. 保存并应用按钮
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        btn_save = Gtk.Button(label="保存并重载 Waybar")
        btn_save.get_style_context().add_class("suggested-action")
        btn_save.set_size_request(160, 36)
        btn_save.connect("clicked", self.on_save_waybar)

        btn_box.pack_end(btn_save, False, False, 0)
        page.pack_start(btn_box, False, False, 10)

        self.stack.add_titled(page, "waybar", "Waybar 状态栏")

    def on_save_waybar(self, button):
        """保存 UI 数据到 Waybar JSON 并触发无缝重载"""
        # 1. 仅**就地就近修改**核心字段，保留用户的自定义模块、样式映射等其他数据
        self.waybar_data["position"] = self.combo_pos.get_active_text()
        self.waybar_data["height"] = int(self.spin_h.get_value())

        if "modules-right" not in self.waybar_data:
            self.waybar_data["modules-right"] = []

        right_modules = self.waybar_data["modules-right"]
        if self.switch_cpu.get_active():
            if "cpu" not in right_modules:
                # 尽量插在前面或者保留原样，这边直接 append
                right_modules.append("cpu")
        else:
            if "cpu" in right_modules:
                right_modules.remove("cpu")

        # 还原回多显示器的外层 Array 结构（如果是的话）
        output_data = self.full_raw_array if self.is_array_config else self.waybar_data

        # 2. 确保配置目录存在并写入 JSON 文件
        try:
            dir_name = os.path.dirname(WAYBAR_CONFIG_PATH)
            if dir_name and not os.path.exists(dir_name):
                os.makedirs(dir_name, exist_ok=True)

            with open(WAYBAR_CONFIG_PATH, "w", encoding="utf-8") as f:
                json.dump(output_data, f, indent=4, ensure_ascii=False)

            # 3. 向 Waybar 发送 SIGUSR2 信号使其热重载
            result = subprocess.run(["pkill", "-SIGUSR2", "waybar"], check=False)

            if result.returncode == 0:
                self.show_message_dialog(
                    Gtk.MessageType.INFO,
                    "保存成功",
                    "Waybar 配置已无缝重载！",
                )
            else:
                self.show_message_dialog(
                    Gtk.MessageType.WARNING,
                    "保存成功但未重载",
                    "配置已写入，但未检测到正在运行的 Waybar 进程。",
                )

        except Exception as e:
            self.show_message_dialog(
                Gtk.MessageType.ERROR, "保存失败", f"无法写入配置文件:\n{e}"
            )

    def init_labwc_page(self):
        """Labwc 占位面板"""
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        page.set_margin_top(24)
        page.set_margin_start(32)
        lbl = Gtk.Label(label="Labwc 窗口管理器设置面板")
        lbl.get_style_context().add_class("page-title")
        page.pack_start(lbl, False, False, 0)
        self.stack.add_titled(page, "labwc", "Labwc 窗口")

    def apply_custom_css(self):
        css = """
        stacksidebar { background-color: #232731; border-right: 1px solid #2e3440; }
        stacksidebar row { padding: 12px 16px; color: #d8dee9; font-size: 13px; }
        stacksidebar row:selected { background-color: #3b4252; color: #88c0d0; border-left: 4px solid #88c0d0; }
        stack { background-color: #2e3440; }
        .page-title { color: #ffffff; font-size: 18px; font-weight: 700; }
        .settings-card { background-color: #232731; border-radius: 8px; border: 1px solid #3b4252; }
        .item-label { color: #e5e9f0; font-size: 13px; }
        button.suggested-action { 
            background-image: none; 
            background-color: #81a1c1; 
            color: #2e3440; 
            font-weight: bold; 
            border-radius: 6px;
        }
        button.suggested-action:hover { background-color: #88c0d0; }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )


if __name__ == "__main__":
    win = ConfigCenter()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

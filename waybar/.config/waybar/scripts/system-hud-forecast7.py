#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：system-hud-forecast7-text.py
# Description：高颜值桌面 7 天天气预报挂件（原生极简文字版、Wayland 透明自适应）

import json
import threading
import time
import urllib.request
from datetime import datetime

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


class WeatherForecastCenter(Gtk.Window):
    def __init__(self):
        super().__init__(title="Weather HUD Forecast")
        self.is_running = True

        # ---- Wayland Layer Shell 核心常驻桌面配置 ----
        if HAS_LAYER_SHELL:
            GtkLayerShell.init_for_window(self)
            GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
            # 💡 修复：显式传入 self 作为第一个参数
            GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        else:
            self.set_decorated(False)
            self.set_keep_above(True)

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and screen.is_composited():
            self.set_visual(visual)

        # 外层深色紧凑面板盒子
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        main_vbox.set_halign(Gtk.Align.END)
        main_vbox.set_margin_top(80)  # 与桌面顶部保留避让距离
        main_vbox.set_margin_end(20)  # 靠右留白
        main_vbox.get_style_context().add_class("hud-panel")
        self.add(main_vbox)

        # 头部标题区域
        title_label = Gtk.Label(label="7-DAY FORECAST")
        title_label.get_style_context().add_class("hud-title")
        title_label.set_alignment(0, 0.5)
        main_vbox.pack_start(title_label, False, False, 0)

        # 用于承载 7 天天气预报行的容器列表
        self.list_box = Gtk.ListBox()
        self.list_box.set_selection_mode(Gtk.SelectionMode.NONE)
        self.list_box.get_style_context().add_class("hud-list")
        main_vbox.pack_start(self.list_box, False, False, 0)

        # 全局快捷键与焦点绑定
        self.connect("key-press-event", self.on_key_press)
        self.connect("focus-out-event", lambda w, e: self.close_program())

        self.apply_css()

        # 启动后台异步网络轮询（每1小时更新一次）
        threading.Thread(target=self.weather_data_loop, daemon=True).start()

    def apply_css(self):
        css = """
        window { background-color: transparent; }
        
        .hud-panel {
            background-color: rgba(22, 22, 22, 0.85);
            border-radius: 16px;
            border: 1px solid rgba(255, 255, 255, 0.05);
            padding: 16px;
            min-width: 260px;
        }
        
        .hud-title {
            color: #81A1C1;
            font-size: 11px;
            font-weight: 800;
            font-family: "JetBrains Mono", "monospace";
            margin-bottom: 12px;
            letter-spacing: 1px;
        }
        
        .hud-list {
            background-color: transparent;
        }
        
        /* 每一行卡片的极简质感 */
        .weather-row {
            padding: 8px 4px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.03);
        }
        
        .text-date {
            color: #EEEEEE;
            font-size: 12px;
            font-weight: 600;
            font-family: "JetBrains Mono", "monospace";
        }
        
        .text-status {
            color: #888888;
            font-size: 11px;
            font-family: "JetBrains Mono", "monospace";
        }
        
        .text-temp {
            color: #FFFFFF;
            font-size: 12px;
            font-weight: 600;
            font-family: "JetBrains Mono", "monospace";
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

    def get_status_text(self, code):
        """将 WMO Code 映射成极简中文/英文天气描述"""
        mapping = {
            0: "晴天 Sunny",
            1: "晴朗 Clear",
            2: "多云 Cloudy",
            3: "阴天 Overcast",
            45: "有雾 Foggy",
            48: "霾雾 Mist",
            51: "毛毛雨 Drizzle",
            53: "毛毛雨 Drizzle",
            55: "毛毛雨 Drizzle",
            61: "小雨 Light Rain",
            63: "中雨 Rain",
            65: "大雨 Heavy Rain",
            71: "小雪 Light Snow",
            73: "中雪 Snow",
            75: "大雪 Heavy Snow",
            80: "阵雨 Showers",
            81: "阵雨 Showers",
            82: "暴阵雨 Showers",
            95: "雷阵雨 Thunderstorm",
        }
        return mapping.get(code, "阴/雨 Rain/Cloudy")

    def update_ui(self, forecast_list):
        """清空旧列表，重新构建 7 天预报文字行"""
        # 清空现有子组件
        for child in self.list_box.get_children():
            self.list_box.remove(child)

        for day in forecast_list[:7]:
            # 创建单行容器
            row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
            row_box.get_style_context().add_class("weather-row")

            # 1. 日期与星期解析 (2026-05-25 -> 05/25 Mon)
            try:
                dt = datetime.strptime(day["date"], "%Y-%m-%d")
                date_str = dt.strftime("%m/%d")
                week_str = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][
                    dt.weekday()
                ]
                full_date = f"{date_str} {week_str}"
            except Exception:
                full_date = day["date"]

            lbl_date = Gtk.Label(label=full_date)
            lbl_date.get_style_context().add_class("text-date")
            lbl_date.set_alignment(0, 0.5)
            row_box.pack_start(lbl_date, False, False, 0)

            # 2. 天气状态文字 (置于中间占满剩余空间)
            status_text = self.get_status_text(day["code"])
            lbl_status = Gtk.Label(label=status_text)
            lbl_status.get_style_context().add_class("text-status")
            lbl_status.set_alignment(0.5, 0.5)  # 居中对齐
            row_box.pack_start(lbl_status, True, True, 0)

            # 3. 最低 ~ 最高温范围
            temp_str = f"{int(day['min'])}° ~ {int(day['max'])}°C"
            lbl_temp = Gtk.Label(label=temp_str)
            lbl_temp.get_style_context().add_class("text-temp")
            lbl_temp.set_alignment(1, 0.5)  # 右对齐
            row_box.pack_start(lbl_temp, False, False, 0)

            self.list_box.add(row_box)

        self.show_all()

    def weather_data_loop(self):
        """完全异步清洗转换 Open-Meteo 天气数据流"""
        lat = "39.9075"
        long = "116.3972"
        api_url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={long}&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=7"

        while self.is_running:
            try:
                req = urllib.request.Request(
                    api_url, headers={"User-Agent": "Mozilla/5.0"}
                )
                with urllib.request.urlopen(req, timeout=12) as response:
                    data = json.loads(response.read().decode())

                daily = data["daily"]
                forecast_list = []
                for i in range(len(daily["time"])):
                    forecast_list.append(
                        {
                            "date": daily["time"][i],
                            "code": daily["weather_code"][i],
                            "min": daily["temperature_2m_min"][i],
                            "max": daily["temperature_2m_max"][i],
                        }
                    )

                # 安全推送到主线程渲染
                GLib.idle_add(self.update_ui, forecast_list)

            except Exception as e:
                print(f"Weather sync failed: {e}")

            time.sleep(3600)  # 每小时刷新

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_program()

    def configure_callback(self, window, event):
        return False

    def close_program(self):
        if self.is_running:
            self.is_running = False
            self.destroy()
            Gtk.main_quit()


if __name__ == "__main__":
    win = WeatherForecastCenter()
    win.connect("destroy", lambda w: win.close_program())
    win.show_all()
    Gtk.main()

#!/usr/bin/env python3
import os
import subprocess
import xml.etree.ElementTree as ET

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

CONFIG_PATH = os.path.expanduser("~/.config/labwc/rc.xml")


class LabwcConfigApp(Gtk.Window):
    def __init__(self):
        super().__init__(title="Labwc 配置中心")
        self.set_default_size(400, 200)
        self.set_border_width(15)

        # 尝试解析 XML
        self.tree = ET.parse(CONFIG_PATH)
        self.root = self.tree.getroot()

        # 布局
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(vbox)

        # 示例：修改窗口抗锯齿或某个开关
        # 假设我们在 XML 中寻找 <core><gap> 标签（隙缝大小）
        gap_element = self.root.find(".//core/gap")
        current_gap = gap_element.text if gap_element is not None else "0"

        lbl = Gtk.Label(label=f"窗口间距 (Gaps):")
        lbl.set_alignment(0, 0.5)
        vbox.pack_start(lbl, False, False, 0)

        # 调整间距的滑动条
        self.spin_button = Gtk.SpinButton.new_with_range(0, 100, 1)
        self.spin_button.set_value(float(current_gap))
        vbox.pack_start(self.spin_button, False, False, 0)

        # 保存并应用按钮
        btn_apply = Gtk.Button(label="应用配置")
        btn_apply.connect("clicked", self.on_apply_clicked)
        vbox.pack_end(btn_apply, False, False, 0)

    def on_apply_clicked(self, button):
        # 1. 将 UI 的值写回 XML 树
        new_gap = str(int(self.spin_button.get_value()))
        gap_element = self.root.find(".//core/gap")
        if gap_element is not None:
            gap_element.text = new_gap

        # 2. 保存文件
        self.tree.write(CONFIG_PATH, encoding="utf-8", xml_declaration=True)

        # 3. 通知 labwc 刷新
        subprocess.run(["labwc", "--reconfigure"])
        print("Labwc 配置已重载！")


if __name__ == "__main__":
    # 注意：实际开发中需先判断文件是否存在，若不存在则从 /etc/xdg/labwc/ 复制一份
    win = LabwcConfigApp()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

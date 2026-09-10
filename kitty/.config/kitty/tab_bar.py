"""draw kitty tab"""
# pyright: reportMissingImports=false
# pylint: disable=E0401,C0116,C0103,W0603,R0913

import datetime
import os
import re
import subprocess
import sys
import time

from kitty.fast_data_types import Screen, get_options
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
    draw_tab_with_powerline,
    draw_title,
)
from kitty.utils import color_as_int

opts = get_options()

ICON: str = "   "
ICON_LENGTH: int = len(ICON)
ICON_FG: int = 0
# ICON_BG: int = as_rgb(color_as_int(opts.color16))
ICON_BG: int = 0

CLOCK_FG = 0
CLOCK_BG = 0
DATE_FG = 0
DATE_BG = as_rgb(color_as_int(opts.color8))

BATTERY_REFRESH = 30  # 秒, 避免频繁读取
_battery_cache: dict = {"t": 0.0, "text": "", "color": 0}


def _battery() -> tuple[str, int]:
    """返回 (显示文本, 前景色). 颜色 0 表示使用默认前景色. 跨平台: macOS 用 pmset, Linux 用 /sys."""
    now = time.monotonic()
    if now - _battery_cache["t"] >= BATTERY_REFRESH:
        text, color = "", 0
        try:
            if sys.platform == "darwin":
                info = _battery_macos()
            else:
                info = _battery_linux()
            if info:
                pct, on_ac = info
                if on_ac:
                    icon = "\uf0e7"  # 电源插头
                elif pct >= 90:
                    icon = "\uf240"  # 满电
                elif pct >= 60:
                    icon = "\uf241"
                elif pct >= 30:
                    icon = "\uf242"
                elif pct >= 10:
                    icon = "\uf243"
                else:
                    icon = "\uf244"  # 空电
                if not on_ac and pct < 20:
                    color = as_rgb(0xFF0000)  # 低电量标红
                text = f" {icon} {pct}% "
        except Exception:
            pass
        _battery_cache["t"] = now
        _battery_cache["text"] = text
        _battery_cache["color"] = color
    return _battery_cache["text"], _battery_cache["color"]


def _battery_macos() -> tuple[int, bool] | None:
    out = subprocess.check_output(
        ["pmset", "-g", "batt"], stderr=subprocess.DEVNULL, timeout=2
    ).decode("utf-8", "replace")
    m = re.search(r"(\d+)%", out)
    if not m:
        return None
    on_ac = "AC Power" in out or "AC attached" in out
    return int(m.group(1)), on_ac


def _read_sys(path: str, name: str) -> str | None:
    try:
        with open(os.path.join(path, name)) as f:
            return f.read().strip()
    except Exception:
        return None


def _battery_linux() -> tuple[int, bool] | None:
    base = "/sys/class/power_supply"
    if not os.path.isdir(base):
        return None
    bats = [os.path.join(base, x) for x in os.listdir(base) if "BAT" in x]
    if not bats:
        return None
    cap = _read_sys(bats[0], "capacity")
    if cap is None:
        return None
    status = _read_sys(bats[0], "status") or "Discharging"
    on_ac = status != "Discharging"
    for name in os.listdir(base):
        if name.startswith("AC") or name.startswith("ADP"):
            if _read_sys(os.path.join(base, name), "online") == "1":
                on_ac = True
                break
    return int(cap), on_ac


def _draw_icon(screen: Screen, index: int) -> int:
    if index != 1:
        return screen.cursor.x

    fg, bg, bold, italic = (
        screen.cursor.fg,
        screen.cursor.bg,
        screen.cursor.bold,
        screen.cursor.italic,
    )
    screen.cursor.bold, screen.cursor.italic, screen.cursor.fg, screen.cursor.bg = (
        True,
        False,
        ICON_FG,
        ICON_BG,
    )
    screen.draw(ICON)
    # set cursor position
    screen.cursor.x = ICON_LENGTH
    # restore color style
    screen.cursor.fg, screen.cursor.bg, screen.cursor.bold, screen.cursor.italic = (
        fg,
        bg,
        bold,
        italic,
    )
    return screen.cursor.x


def _draw_left_status(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
    use_kitty_render_function: bool = False,
) -> int:
    if use_kitty_render_function:
        # Use `kitty` function render tab
        end = draw_tab_with_powerline(
            draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
        )
        return end

    if draw_data.leading_spaces:
        screen.draw(" " * draw_data.leading_spaces)

    # draw tab title
    draw_title(draw_data, screen, tab, index)

    trailing_spaces = min(max_title_length - 1, draw_data.trailing_spaces)
    max_title_length -= trailing_spaces
    extra = screen.cursor.x - before - max_title_length
    if extra > 0:
        screen.cursor.x -= extra + 1
        # Don't change `ICON`
        screen.cursor.x = max(screen.cursor.x, ICON_LENGTH)
        screen.draw("…")
    if trailing_spaces:
        screen.draw(" " * trailing_spaces)

    screen.cursor.bold = screen.cursor.italic = False
    screen.cursor.fg = 0
    if not is_last:
        screen.cursor.bg = as_rgb(color_as_int(draw_data.inactive_bg))
        screen.draw(draw_data.sep)
    screen.cursor.bg = 0
    return screen.cursor.x


def _draw_right_status(screen: Screen, is_last: bool) -> int:
    if not is_last:
        return screen.cursor.x

    bat_text, bat_color = _battery()
    cells = [
        (bat_color, CLOCK_BG, bat_text),
        (CLOCK_FG, CLOCK_BG, datetime.datetime.now().strftime(" %H:%M ")),
    ]

    right_status_length = 0
    for _, _, cell in cells:
        right_status_length += len(cell)

    draw_spaces = screen.columns - screen.cursor.x - right_status_length
    if draw_spaces > 0:
        screen.draw(" " * draw_spaces)

    for fg, bg, cell in cells:
        screen.cursor.fg = fg
        screen.cursor.bg = bg
        screen.draw(cell)
    screen.cursor.fg = 0
    screen.cursor.bg = 0

    screen.cursor.x = max(screen.cursor.x, screen.columns - right_status_length)
    return screen.cursor.x


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    _draw_icon(screen, index)
    # Set cursor to where `left_status` ends, instead `right_status`,
    # to enable `open new tab` feature
    end = _draw_left_status(
        draw_data,
        screen,
        tab,
        before,
        max_title_length,
        index,
        is_last,
        extra_data,
        use_kitty_render_function=False,
    )
    _draw_right_status(
        screen,
        is_last,
    )
    return end

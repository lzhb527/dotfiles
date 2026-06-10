import math
import os
import socket
import sys
import time

import psutil

# 检查系统类型
IS_WINDOWS = sys.platform == "win32"

if IS_WINDOWS:
    import msvcrt
else:
    import select
    import termios
    import tty

# 屏幕与甜甜圈配置
SCREEN_WIDTH = 120
SCREEN_HEIGHT = 30
DONUT_WIDTH = 40
INFO_ROWS = 9


class SystemMonitorDonut:
    def __init__(self):
        self.A = 0.0
        self.B = 0.0
        self.text_timer = 0
        self.last_ip_check = 0
        self.local_ip = "Fetching..."
        self.orig_settings = None

    def enable_raw_mode(self):
        """开启终端原始模式，用于非阻塞读取键盘"""
        if not IS_WINDOWS:
            self.orig_settings = termios.tcgetattr(sys.stdin)
            tty.setraw(sys.stdin.fileno())
            # 设置为非阻塞
            # fd = sys.stdin.fileno()
            # old_flags = fcntl.fcntl(fd, fcntl.F_GETFL)
            # fcntl.fcntl(fd, fcntl.F_SETFL, old_flags | os.O_NONBLOCK)

    def cleanup(self):
        """恢复终端显示状态"""
        # \x1b[?25h 显示光标, \x1b[2J 清屏, \x1b[H 光标复位
        # 注意：在 raw 模式下，换行必须用 \r\n 否则排版会乱
        sys.stdout.write("\x1b[?25h\x1b[2J\x1b[H\x1b[0m\r\n")
        sys.stdout.flush()
        if self.orig_settings and not IS_WINDOWS:
            termios.tcsetattr(sys.stdin, termios.TCSAFLUSH, self.orig_settings)

    def check_keyboard_quit(self):
        """非阻塞检测用户是否按了 'q'"""
        if IS_WINDOWS:
            if msvcrt.kbhit():
                ch = msvcrt.getch().decode(errors="ignore")
                if ch.lower() == "q":
                    return True
        else:
            r, _, _ = select.select([sys.stdin], [], [], 0.0)
            if r:
                ch = sys.stdin.read(1)
                if ch.lower() == "q":
                    return True
        return False

    def get_local_ip(self):
        """安全高效地获取本地局域网 IP"""
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except Exception:
            return "127.0.0.1"

    def get_system_status(self):
        """获取系统各项指标"""
        now = time.time()

        # 1. 定时刷新 IP (每 10 秒)
        if now - self.last_ip_check >= 10 or self.last_ip_check == 0:
            self.local_ip = self.get_local_ip()
            self.last_ip_check = now

        # 2. 获取运行时间 (Uptime)
        try:
            boot_time = psutil.boot_time()
            uptime_s = int(now - boot_time)
            days, rem = divmod(uptime_s, 86400)
            hours, rem = divmod(rem, 3600)
            mins, _ = divmod(rem, 60)
            uptime_str = f"{days}d {hours}h {mins}m"
        except:
            uptime_str = "N/A"

        # 3. 获取内存
        mem = psutil.virtual_memory()
        free_mb = int(mem.available / (1024 * 1024))
        total_mb = int(mem.total / (1024 * 1024))

        # 4. 获取电池
        battery = psutil.sensors_battery()
        bat_str = f"{int(battery.percent)}%" if battery else "N/A (AC POWERED)"

        # 5. 获取系统负载
        try:
            load = os.getloadavg()
            load_str = f"{load[0]:.2f}, {load[1]:.2f}, {load[2]:.2f}"
        except AttributeError:
            load_str = (
                f"{psutil.cpu_percent()}% (CPU USE)"  # Windows 下用 CPU 使用率代替
            )

        # 组装 9 行数据
        sys_info = [
            "=== SYSTEM STATUS ===",
            f"TIME    : {time.strftime('%Y-%m-%d %H:%M:%S')}",
            f"UPTIME  : {uptime_str}",
            f"MEMORY  : {free_mb}MB / {total_mb}MB (Free/Total)",
            f"LOCAL IP: {self.local_ip}",
            f"BATTERY : {bat_str}",
            f"LOAD    : {load_str}",
            f"ROTATION: A={self.A:.2f}, B={self.B:.2f}",
            "STATUS  : RUNNING [PRESS 'Q' TO QUIT]",
        ]
        return sys_info

    def render_donut(self):
        """经典 ASCII 甜甜圈 3D 渲染核心"""
        buffer = [[" " for _ in range(SCREEN_WIDTH)] for _ in range(SCREEN_HEIGHT)]
        zbuffer = [[0.0 for _ in range(SCREEN_WIDTH)] for _ in range(SCREEN_HEIGHT)]

        j = 0.0
        while j < 6.28:
            i = 0.0
            while i < 6.28:
                c = math.sin(i)
                d = math.cos(j)
                e = math.sin(self.A)
                f = math.sin(j)
                g = math.cos(self.A)
                h = d + 2
                D = 1 / (c * h * e + f * g + 5)
                l = math.cos(i)
                m = math.cos(self.B)
                n = math.sin(self.B)
                t = c * h * g - f * e

                x = int(DONUT_WIDTH / 2 + 15 * D * (l * h * m - t * n))
                y = int(SCREEN_HEIGHT / 2 + 12 * D * (l * h * n + t * m))
                N = int(8 * ((f * e - c * d * g) * m - c * d * e - f * g - l * d * n))

                if 0 <= y < SCREEN_HEIGHT and 0 <= x < DONUT_WIDTH:
                    if D > zbuffer[y][x]:
                        zbuffer[y][x] = D
                        luminance_index = N if N > 0 else 0
                        chars = ".,-~:;=!*#$@"
                        buffer[y][x] = (
                            chars[luminance_index]
                            if luminance_index < len(chars)
                            else chars[-1]
                        )
                i += 0.02
            j += 0.07
        return buffer

    def run(self):
        # 隐藏光标 + 首次清屏
        sys.stdout.write("\x1b[2J\x1b[?25l")
        sys.stdout.flush()
        self.enable_raw_mode()

        try:
            while True:
                # 键盘退出检查
                if self.check_keyboard_quit():
                    break

                sys_info = self.get_system_status()
                donut_buf = self.render_donut()

                # 构建画布输出流
                output = ["\x1b[H"]  # 将光标移回左上角 (0,0)
                start_y = (SCREEN_HEIGHT - INFO_ROWS) // 2

                for y in range(SCREEN_HEIGHT):
                    # 1. 拼接甜甜圈
                    line_chars = "".join(donut_buf[y][:DONUT_WIDTH])
                    output.append(line_chars + "    ")

                    # 2. 拼接右侧看板
                    if start_y <= y < start_y + INFO_ROWS:
                        info_idx = y - start_y
                        info_line = sys_info[info_idx]
                        length = len(info_line)

                        output.append("\x1b[32m")  # 开启绿字
                        for col in range(length):
                            if col < self.text_timer:
                                output.append(info_line[col])
                            elif col == self.text_timer:
                                output.append("█")
                            else:
                                output.append(" ")
                        output.append("\x1b[0m")  # 恢复颜色

                    # 关键修改：在原始终端模式下，必须使用 \r\n 换行，否则排版会错乱斜切
                    output.append("\x1b[K\r\n")

                # 一次性全屏刷新，极其丝滑
                sys.stdout.write("".join(output))
                sys.stdout.flush()

                # 计数器与角度递增
                self.text_timer = 0 if self.text_timer > 65 else self.text_timer + 1
                self.A += 0.04
                self.B += 0.02
                time.sleep(0.03)

        finally:
            self.cleanup()


if __name__ == "__main__":
    monitor = SystemMonitorDonut()
    monitor.run()


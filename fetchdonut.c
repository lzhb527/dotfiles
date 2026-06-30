#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>

#define SCREEN_WIDTH 80
#define SCREEN_HEIGHT 30
#define DONUT_WIDTH 40

// 保存原始终端设置，以便退出时恢复
struct termios orig_termios;

// 退出时的清理函数：恢复光标和终端设置
void cleanup() {
    printf("\x1b[?25h\x1b[2J\x1b[H"); // 显示光标，清屏
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios); // 恢复终端属性
}

// 初始化非阻塞、不回显的键盘输入模式
void enable_raw_mode() {
    tcgetattr(STDIN_FILENO, &orig_termios);
    atexit(cleanup); // 确保程序无论是正常退出还是崩溃，都会执行 cleanup

    struct termios raw = orig_termios;
    raw.c_lflag &= ~(ECHO | ICANON); // 关闭回显（不显示输入的 q），关闭规范模式（按键不用输回车）
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);

    // 设置标准输入为非阻塞模式（如果没有按键，read 不会卡住程序）
    int flags = fcntl(STDIN_FILENO, F_GETFL, 0);
    fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK);
}

int main() {
    // 1. 初始化终端：隐藏光标并启用按键监听
    printf("\x1b[2J\x1b[?25l");
    enable_raw_mode();

    // 2. 内存中调用 fastfetch 并读取静态输出
    char ff_lines[SCREEN_HEIGHT][256] = {0};
    int ff_line_count = 0;
    
    FILE *fp = popen("fastfetch --logo none  2>/dev/null", "r");
    if (fp != NULL) {
        while (ff_line_count < SCREEN_HEIGHT && fgets(ff_lines[ff_line_count], sizeof(ff_lines[0]), fp)) {
            ff_lines[ff_line_count][strcspn(ff_lines[ff_line_count], "\n")] = 0;
            ff_line_count++;
        }
        pclose(fp);
    }

    // 3. 甜甜圈参数
    float A = 0, B = 0;
    float i, j;
    char buffer[SCREEN_HEIGHT][SCREEN_WIDTH];
    float zbuffer[SCREEN_HEIGHT][SCREEN_WIDTH];

    // 4. 渲染主循环
    while (1) {
        // 【核心控制】：实时检测键盘输入
        char ch;
        if (read(STDIN_FILENO, &ch, 1) == 1) {
            if (ch == 'q' || ch == 'Q') {
                break; // 监测到 q 键，直接跳出循环触发 cleanup 退出
            }
        }

        // 清空画布
        memset(buffer, ' ', sizeof(buffer));
        memset(zbuffer, 0, sizeof(zbuffer));

        // 渲染 3D 甜甜圈
        for(j = 0; j < 6.28; j += 0.07) {
            for(i = 0; i < 6.28; i += 0.02) {
                float c = sin(i), d = cos(j), e = sin(A), f = sin(j), g = cos(A);
                float h = d + 2, D = 1 / (c * h * e + f * g + 5);
                float l = cos(i), m = cos(B), n = sin(B);
                float t = c * h * g - f * e;

                int x = (int)(DONUT_WIDTH / 2 + 15 * D * (l * h * m - t * n));
                int y = (int)(SCREEN_HEIGHT / 2 + 12 * D * (l * h * n + t * m)); 

                int N = (int)(8 * ((f * e - c * d * g) * m - c * d * e - f * g - l * d * n));

                if(y >= 0 && y < SCREEN_HEIGHT && x >= 0 && x < DONUT_WIDTH) {
                    if(D > zbuffer[y][x]) {
                        zbuffer[y][x] = D;
                        buffer[y][x] = ".,-~:;=!*#$@"[N > 0 ? N : 0];
                    }
                }
            }
        }

        // 原地无闪烁重绘
        printf("\x1b[H"); 
        for (int y = 0; y < SCREEN_HEIGHT; y++) {
            for (int x = 0; x < DONUT_WIDTH; x++) {
                putchar(buffer[y][x]);
            }
            printf("   "); // 间距
            if (y < ff_line_count) {
                printf("%s", ff_lines[y]);
            }
            printf("\x1b[K\n");
        }

        A += 0.04;
        B += 0.02;
        usleep(30000); // 控制帧率
    }

    // 正常退出（会触发 atexit 绑定的 cleanup）
    return 0;
}


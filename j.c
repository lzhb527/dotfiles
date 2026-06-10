#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>
#include <time.h>

// 跨平台头文件条件编译
#ifdef __linux__
    #include <sys/sysinfo.h> // 用于 Linux 获取内存和运行时间
#elif defined(__APPLE__)
    #include <sys/sysctl.h>  // 用于 macOS 获取基础系统信息
    #include <sys/types.h>
    #include <mach/mach.h>   // 用于 macOS 获取更底层的精准实时内存
#endif

#define SCREEN_WIDTH 120
#define SCREEN_HEIGHT 30
#define DONUT_WIDTH 40
#define INFO_ROWS 8 // 增加到 8 行信息

struct termios orig_termios;

void cleanup() {
    printf("\x1b[?25h\x1b[2J\x1b[H\x1b[0m");
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
}

void enable_raw_mode() {
    tcgetattr(STDIN_FILENO, &orig_termios);
    atexit(cleanup);
    struct termios raw = orig_termios;
    raw.c_lflag &= ~(ECHO | ICANON);
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
    int flags = fcntl(STDIN_FILENO, F_GETFL, 0);
    fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK);
}

// 封装跨平台获取运行时间函数（秒数）
long get_system_uptime() {
#ifdef __linux__
    struct sysinfo si;
    if (sysinfo(&si) == 0) return si.uptime;
#elif defined(__APPLE__)
    struct timeval boottime;
    size_t size = sizeof(boottime);
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) == 0) {
        return (long)(time(NULL) - boottime.tv_sec);
    }
#endif
    return 0;
}

// 封装跨平台获取内存函数（结果单位：MB）
void get_system_memory(long *total_mb, long *free_mb) {
    *total_mb = 0;
    *free_mb = 0;
#ifdef __linux__
    struct sysinfo si;
    if (sysinfo(&si) == 0) {
        *total_mb = (si.totalram * si.mem_unit) / (1024 * 1024);
        *free_mb = (si.freeram * si.mem_unit) / (1024 * 1024);
    }
#elif defined(__APPLE__)
    // 1. 获取物理总内存
    long long memsize = 0;
    size_t size = sizeof(memsize);
    int mib[2] = {CTL_HW, HW_MEMSIZE};
    if (sysctl(mib, 2, &memsize, &size, NULL, 0) == 0) {
        *total_mb = memsize / (1024 * 1024);
    }
    // 2. 获取空闲页面大小并计算空闲内存
    mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
    vm_statistics64_data_t vm_stats;
    if (host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info64_t)&vm_stats, &count) == KERN_SUCCESS) {
        // macOS 空闲内存 = 纯空闲页 + 投机性留用页
        long long free_bytes = (int64_t)(vm_stats.free_count + vm_stats.speculative_count) * sysconf(_SC_PAGESIZE);
        *free_mb = free_bytes / (1024 * 1024);
    }
#endif
}

// 封装跨平台获取电池电量函数（百分比，失败或无电池返回 -1）
int get_system_battery() {
    int battery_level = -1;
#ifdef __linux__
    FILE *bat_f = fopen("/sys/class/power_supply/BAT0/capacity", "r");
    if (!bat_f) bat_f = fopen("/sys/class/power_supply/BAT1/capacity", "r");
    if (bat_f) {
        if (fscanf(bat_f, "%d", &battery_level) != 1) battery_level = -1;
        fclose(bat_f);
    }
#elif defined(__APPLE__)
    // macOS 通过执行自带命令 pmset 并解析输出获取电量
    FILE *fp = popen("pmset -g batt", "r");
    if (fp) {
        char buf[256];
        while (fgets(buf, sizeof(buf), fp) != NULL) {
            char *pct_ptr = strchr(buf, '%');
            if (pct_ptr) {
                // 往前寻找数字起点
                char *start = pct_ptr;
                while (start > buf && *(start - 1) >= '0' && *(start - 1) <= '9') {
                    start--;
                }
                if (start != pct_ptr) {
                    battery_level = atoi(start);
                    break;
                }
            }
        }
        pclose(fp);
    }
#endif
    return battery_level;
}

int main() {
    printf("\x1b[2J\x1b[?25l");
    enable_raw_mode();

    float A = 0, B = 0;
    float i, j;
    char buffer[SCREEN_HEIGHT][SCREEN_WIDTH];
    float zbuffer[SCREEN_HEIGHT][SCREEN_WIDTH];
    
    int text_timer = 0; 

    while (1) {
        char ch;
        if (read(STDIN_FILENO, &ch, 1) == 1) {
            if (ch == 'q' || ch == 'Q') break;
        }

        // 1. 获取系统动态信息
        char sys_info[INFO_ROWS][128];
        time_t rawtime;
        struct tm *timeinfo;
        time(&rawtime);
        timeinfo = localtime(&rawtime);

        // 使用跨平台封装函数获取运行时间和内存
        long uptime_s = get_system_uptime();
        long total_mem = 0, free_mem = 0;
        get_system_memory(&total_mem, &free_mem);

        // 计算运行时间 (天/时/分)
        long days = uptime_s / 86400;
        long hours = (uptime_s % 86400) / 3600;
        long mins = (uptime_s % 3600) / 60;

        // 使用跨平台封装函数获取电池信息
        int battery_level = get_system_battery();

        // 填充 8 行系统信息
        sprintf(sys_info[0], "=== SYSTEM STATUS ===");
        sprintf(sys_info[1], "TIME    : %04d-%02d-%02d %02d:%02d:%02d", 
                timeinfo->tm_year + 1900, timeinfo->tm_mon + 1, timeinfo->tm_mday,
                timeinfo->tm_hour, timeinfo->tm_min, timeinfo->tm_sec);
        
        // 运行时间
        sprintf(sys_info[2], "UPTIME  : %ldd %ldh %ldm", days, hours, mins);
        
        // 内存信息
        sprintf(sys_info[3], "MEMORY  : %ldMB / %ldMB (Free/Total)", free_mem, total_mem);
        
        // 电池信息
        if (battery_level >= 0) {
            sprintf(sys_info[4], "BATTERY : %d%%", battery_level);
        } else {
            sprintf(sys_info[4], "BATTERY : N/A (AC POWERED)");
        }

        // 系统负载
        double load[3];
        getloadavg(load, 3);
        sprintf(sys_info[5], "LOAD    : %.2f, %.2f, %.2f", load[0], load[1], load[2]);
        
        // 甜甜圈旋转角度
        sprintf(sys_info[6], "ROTATION: A=%.2f, B=%.2f", A, B);
        sprintf(sys_info[7], "STATUS  : RUNNING [PRESS 'Q' TO QUIT]");

        // 2. 渲染甜甜圈 (保持不变)
        memset(buffer, ' ', sizeof(buffer));
        memset(zbuffer, 0, sizeof(zbuffer));
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

        // 3. 打印画布
        printf("\x1b[H"); 
        for (int y = 0; y < SCREEN_HEIGHT; y++) {
            // 打印左侧甜甜圈
            for (int x = 0; x < DONUT_WIDTH; x++) {
                putchar(buffer[y][x]);
            }
            printf("    ");

            // 打印右侧的实时动态打字机文本（居中显示 8 行信息）
            int start_y = (SCREEN_HEIGHT - INFO_ROWS) / 2;
            if (y >= start_y && y < start_y + INFO_ROWS) {
                int info_idx = y - start_y;
                char *line = sys_info[info_idx];
                int len = strlen(line);

                printf("\x1b[32m"); // 绿字黑客风
                for (int col = 0; col < len; col++) {
                    if (col < text_timer) {
                        putchar(line[col]);
                    } else if (col == text_timer) {
                        printf("█"); // 闪烁打字光标
                    } else {
                        putchar(' ');
                    }
                }
                printf("\x1b[0m");
            }
            printf("\x1b[K\n");
        }

        // 逐渐递增显示字符，因为内存和电池信息变长了，限制提高到 60
        text_timer++;
        if (text_timer > 60) text_timer = 0; 

        A += 0.04;
        B += 0.02;
        usleep(30000);
    }
    return 0;
}


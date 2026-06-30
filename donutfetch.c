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
    #include <sys/sysinfo.h> // 用于 Linux 获取运行时间
    #include <sys/utsname.h> // 用于 Linux 获取内核/系统基本信息
#elif defined(__APPLE__)
    #include <sys/sysctl.h>  // 用于 macOS 获取基础系统信息
    #include <sys/types.h>
    #include <mach/mach.h>   // 用于 macOS 获取更底层的精准实时内存
#endif

#define SCREEN_WIDTH 120
#define SCREEN_HEIGHT 30
#define DONUT_WIDTH 40
#define INFO_ROWS 11 //   11 行以完美容纳 OS 信息

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

// 封装跨平台获取操作系统名称函数
void get_system_os(char *os_buf, size_t max_len) {
    strncpy(os_buf, "Unknown OS", max_len);
#ifdef __linux__
    // 优先读取 Linux 的发行版信息
    FILE *fp = fopen("/etc/os-release", "r");
    if (fp) {
        char line[128];
        while (fgets(line, sizeof(line), fp)) {
            if (strncmp(line, "PRETTY_NAME=", 12) == 0) {
                // 提取双引号里面的优美名称
                char *start = strchr(line, '"');
                if (start) {
                    start++;
                    char *end = strchr(start, '"');
                    if (end) *end = '\0';
                    strncpy(os_buf, start, max_len - 1);
                } else {
                    // 如果没有双引号，直接提取等号后面的
                    char *val = line + 12;
                    size_t len = strlen(val);
                    if (len > 0 && val[len-1] == '\n') val[len-1] = '\0';
                    strncpy(os_buf, val, max_len - 1);
                }
                fclose(fp);
                return;
            }
        }
        fclose(fp);
    }
    // 降级方案：使用 uname
    struct utsname un;
    if (uname(&un) == 0) {
        snprintf(os_buf, max_len, "%s %s", un.sysname, un.release);
    }
#elif defined(__APPLE__)
    char str[256];
    size_t size = sizeof(str);
    // 获取 macOS 的内核版本信息
    if (sysctlbyname("kern.osrelease", str, &size, NULL, 0) == 0) {
        snprintf(os_buf, max_len, "macOS (Darwin %s)", str);
    } else {
        strncpy(os_buf, "macOS / OS X", max_len);
    }
#endif
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
    FILE *fp = fopen("/proc/meminfo", "r");
    if (fp) {
        char line[128];
        long total_kb = 0;
        long avail_kb = 0;
        int found = 0;
        while (fgets(line, sizeof(line), fp)) {
            if (strncmp(line, "MemTotal:", 9) == 0) {
                sscanf(line + 9, "%ld", &total_kb);
                found++;
            } else if (strncmp(line, "MemAvailable:", 13) == 0) {
                sscanf(line + 13, "%ld", &avail_kb);
                found++;
            }
            if (found >= 2) break;
        }
        fclose(fp);
        *total_mb = total_kb / 1024;
        *free_mb = avail_kb / 1024;
    }
#elif defined(__APPLE__)
    long long memsize = 0;
    size_t size = sizeof(memsize);
    int mib[2] = {CTL_HW, HW_MEMSIZE};
    if (sysctl(mib, 2, &memsize, &size, NULL, 0) == 0) {
        *total_mb = memsize / (1024 * 1024);
    }
    
    mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
    vm_statistics64_data_t vm_stats;
    if (host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info64_t)&vm_stats, &count) == KERN_SUCCESS) {
        long page_size = sysconf(_SC_PAGESIZE);
        
        long long app_memory = (int64_t)vm_stats.internal_page_count * page_size;
        long long wired_memory = (int64_t)vm_stats.wire_count * page_size;
        long long compressed_memory = (int64_t)vm_stats.compressor_page_count * page_size;
        
        long long used_bytes = app_memory + wired_memory + compressed_memory;
        long long free_bytes = memsize - used_bytes;
        if (free_bytes < 0) free_bytes = 0;
        
        *free_mb = free_bytes / (1024 * 1024);
    }
#endif
}

// 封装跨平台获取电池电量函数
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
    FILE *fp = popen("pmset -g batt", "r");
    if (fp) {
        char buf[256];
        while (fgets(buf, sizeof(buf), fp) != NULL) {
            char *pct_ptr = strchr(buf, '%');
            if (pct_ptr) {
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

// 封装跨平台获取局域网内网 IP 函数
void get_local_ip(char *ip_buf, size_t max_len) {
    strncpy(ip_buf, "N/A", max_len);
    FILE *fp = NULL;
#ifdef __linux__
    fp = popen("ip route get 1.1.1.1 2>/dev/null | awk '{print $7}'", "r");
    if (!fp) fp = popen("hostname -I | awk '{print $1}'", "r");
#elif defined(__APPLE__)
    fp = popen("scutil --nwi | grep 'Network:' | head -n 1 | awk '{print $4}' | xargs ipconfig getifaddr 2>/dev/null", "r");
    if (fp) {
        char test_buf[64] = {0};
        if (fgets(test_buf, sizeof(test_buf), fp) == NULL || strlen(test_buf) <= 1) {
            pclose(fp);
            fp = popen("hostname_ip=$(hostname); if [[ \"$hostname_ip\" == *.local ]]; then ipconfig getifaddr en0; else host \"$hostname_ip\" | awk '{print $4}'; fi", "r");
        } else {
            pclose(fp);
            fp = popen("scutil --nwi | grep 'Network:' | head -n 1 | awk '{print $4}' | xargs ipconfig getifaddr 2>/dev/null", "r");
        }
    }
#endif

    if (fp) {
        if (fgets(ip_buf, max_len, fp) != NULL) {
            size_t len = strlen(ip_buf);
            if (len > 0 && ip_buf[len - 1] == '\n') ip_buf[len - 1] = '\0';
        }
        pclose(fp);
    }
    if (strlen(ip_buf) == 0 || strcmp(ip_buf, "N/A") == 0) strncpy(ip_buf, "127.0.0.1", max_len);
}

int main() {
    printf("\x1b[2J\x1b[?25l");
    enable_raw_mode();

    float A = 0, B = 0;
    float i, j;
    char buffer[SCREEN_HEIGHT][SCREEN_WIDTH];
    float zbuffer[SCREEN_HEIGHT][SCREEN_WIDTH];
    
    int text_timer = 0; 
    
    char local_ip[64] = "Fetching...";
    time_t last_ip_check = 0;

    // 静态信息单次获取，避免循环内重复开销
    char hostname[64] = "Unknown";
    gethostname(hostname, sizeof(hostname));

    char os_info[64] = "Unknown OS";
    get_system_os(os_info, sizeof(os_info));

    while (1) {
        char ch;
        if (read(STDIN_FILENO, &ch, 1) == 1) {
            if (ch == 'q' || ch == 'Q') break;
        }

        time_t now_time;
        time(&now_time);

        if (now_time - last_ip_check >= 10 || last_ip_check == 0) {
            get_local_ip(local_ip, sizeof(local_ip));
            last_ip_check = now_time;
        }

        char sys_info[INFO_ROWS][128];
        struct tm *timeinfo = localtime(&now_time);

        long uptime_s = get_system_uptime();
        long total_mem = 0, free_mem = 0;
        get_system_memory(&total_mem, &free_mem);

        long days = uptime_s / 86400;
        long hours = (uptime_s % 86400) / 3600;
        long mins = (uptime_s % 3600) / 60;

        int battery_level = get_system_battery();

        // 填充 11 行全新的 Donutfetch 数据面板
        sprintf(sys_info[0], "=== DONUTFETCH STATUS ===");
        sprintf(sys_info[1], "OS      : %s", os_info);
        sprintf(sys_info[2], "TIME    : %04d-%02d-%02d %02d:%02d:%02d", 
                timeinfo->tm_year + 1900, timeinfo->tm_mon + 1, timeinfo->tm_mday,
                timeinfo->tm_hour, timeinfo->tm_min, timeinfo->tm_sec);
        
        sprintf(sys_info[3], "UPTIME  : %ldd %ldh %ldm", days, hours, mins);
        sprintf(sys_info[4], "MEMORY  : %ldMB / %ldMB (Avail/Total)", free_mem, total_mem);
        sprintf(sys_info[5], "LOCAL IP: %s", local_ip);

        if (battery_level >= 0) {
            sprintf(sys_info[6], "BATTERY : %d%%", battery_level);
        } else {
            sprintf(sys_info[6], "BATTERY : N/A (AC POWERED)");
        }

        double load[3];
        getloadavg(load, 3);
        sprintf(sys_info[7], "LOAD    : %.2f, %.2f, %.2f", load[0], load[1], load[2]);
        
        sprintf(sys_info[8], "ROTATION: A=%.2f, B=%.2f", A, B);
        sprintf(sys_info[9], "AUTHOR  : lzhb527@126.com");
        sprintf(sys_info[10], "STATUS  : RUNNING [PRESS 'Q' TO QUIT]");

        // 3. 渲染甜甜圈
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

        // 4. 打印画布
        printf("\x1b[H"); 
        for (int y = 0; y < SCREEN_HEIGHT; y++) {
            for (int x = 0; x < DONUT_WIDTH; x++) {
                putchar(buffer[y][x]);
            }
            printf("    ");

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
                        printf("█"); 
                    } else {
                        putchar(' ');
                    }
                }
                printf("\x1b[0m");
            }
            printf("\x1b[K\n");
        }

        text_timer++;
        // 适当放宽打字机上限以支持可能较长的 Linux 发行版名称
        if (text_timer > 80) text_timer = 0; 

        A += 0.04;
        B += 0.02;
        usleep(30000);
    }
    return 0;
}

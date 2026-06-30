#!/bin/bash
# Filename：weather.sh
# Author：lizhengbei

# 坐标设置 (北京)
lat="39.9075"
long="116.3972"
days="16" # 👈 在这里修改天数，支持 1 到 16 天

# 1. 请求 API (加入了 &forecast_days=$days)
weather_json=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${long}&current=temperature,weathercode&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=${days}")

if [ -z "$weather_json" ] || echo "$weather_json" | grep -q "error"; then
    echo "获取天气数据失败，请检查网络或坐标设置。"
    exit 1
fi

# 2. 图标转换函数
get_icon() {
    local code="$1"
    case "$code" in
    0 | 1) echo " " ;;                       # 晴
    2 | 3) echo " " ;;                       # 多云/阴
    45 | 48) echo " " ;;                     # 雾
    51 | 53 | 55 | 56 | 57) echo " " ;;      # 毛毛雨
    61 | 63 | 65 | 66 | 67) echo " " ;;      # 小到大雨
    71 | 73 | 75 | 77 | 85 | 86) echo "󰼶 " ;; # 雪
    80 | 81 | 82) echo " " ;;                # 阵雨
    95 | 96 | 99) echo " " ;;                # 雷阵雨
    *) echo " " ;;                           # 未知
    esac
}

# --- 打印当前天气 ---
current_tem=$(echo "$weather_json" | jq '.current.temperature')
current_code=$(echo "$weather_json" | jq '.current.weathercode')
current_icon=$(get_icon "$current_code")

echo "============================="
echo "  当前天气: $current_icon ${current_tem}°C"
echo "============================="
echo "  未来 ${days} 天天气预报 (日期 | 天气 | 最低温~最高温)"
echo "-----------------------------"

# --- 🛠️ 修复后的循环解析逻辑 ---
# 使用 range(0; .daily.time | length) 动态获取天数，安全、绝不报错
echo "$weather_json" | jq -r '
  .daily | 
  range(0; .time | length) as $i | 
  "\(.time[$i]),\(.weather_code[$i]),\(.temperature_2m_min[$i]),\(.temperature_2m_max[$i])"
' | while IFS=',' read -r date code min_temp max_temp; do

    # 如果某天数据残缺，跳过或显示 N/A
    [ "$date" = "null" ] && continue

    day_icon=$(get_icon "$code")

    # 格式化输出
    printf "  %s   %s   %5s°C ~ %5s°C\n" "$date" "$day_icon" "$min_temp" "$max_temp"
done
echo "============================="

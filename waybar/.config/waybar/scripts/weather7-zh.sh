#!/bin/bash
# Filename：weather7-zh.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-06-03
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
# Filename：weather.sh
# Author：lizhengbei

# 坐标设置 (北京)
lat="39.9075"
long="116.3972"
days="7" # 建议设为 7 天更清晰，支持 1 到 16 天

# 1. 请求 API
weather_json=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${long}&current=temperature,weathercode&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=${days}")

if [ -z "$weather_json" ] || echo "$weather_json" | grep -q "error"; then
    echo "获取天气数据失败，请检查网络或坐标设置。"
    exit 1
fi

# 2. 修改后的转换函数：返回 "图标 描述"
get_weather_info() {
    local code="$1"
    case "$code" in
    0 | 1) echo "  晴朗" ;;
    2 | 3) echo "  多云" ;;
    45 | 48) echo "  雾天" ;;
    51 | 53 | 55 | 56 | 57) echo "  毛毛雨" ;;
    61 | 63 | 65 | 66 | 67) echo "  雨天" ;;
    71 | 73 | 75 | 77 | 85 | 86) echo "    雪天" ;;
    80 | 81 | 82) echo "  阵雨" ;;
    95 | 96 | 99) echo "  雷阵雨" ;;
    *) echo "  未知" ;;
    esac
}

# --- 打印当前天气 ---
current_tem=$(echo "$weather_json" | jq '.current.temperature')
current_code=$(echo "$weather_json" | jq '.current.weathercode')
current_info=$(get_weather_info "$current_code")

echo "============================="
echo "  当前天气: $current_info ${current_tem}°C"
echo "============================="
echo "  未来 ${days} 天天气预报"
echo "-----------------------------"

# --- 循环解析逻辑 ---
echo "$weather_json" | jq -r '
  .daily | 
  range(0; .time | length) as $i | 
  "\(.time[$i]),\(.weather_code[$i]),\(.temperature_2m_min[$i]),\(.temperature_2m_max[$i])"
' | while IFS=',' read -r date code min_temp max_temp; do

    [ "$date" = "null" ] && continue

    # 获取图标和文字描述
    day_info=$(get_weather_info "$code")

    # 格式化输出：调整了间距以对齐中文
    printf "  %10s   %-10s   %5s°C ~ %5s°C\n" "$date" "$day_info" "$min_temp" "$max_temp"
done
echo "============================="

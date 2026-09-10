#!/bin/bash
# Filename：weather-zh.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-06-03
# Description：Waybar 专属北京天气脚本（Nerd Fonts 图标补全版）
# Copyright (C) 2026  Ltd. All rights reserved.

# 经纬度：北京
lat="39.9075"
long="116.3972"

# 获取天气数据
weather=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${long}&current=temperature,weathercode")

# 使用 -r 参数去掉 jq 输出的潜在双引号
tem=$(echo "$weather" | jq -r '.current.temperature')
wea=$(echo "$weather" | jq '.current.weathercode')

# 完整代码映射 (已补全 Nerd Fonts 图标)
case $wea in
0)
    curwea="" # 󰖙
    desc="晴朗"
    ;;
1)
    curwea="" # 󰖕
    desc="大部晴朗"
    ;;
2)
    curwea="" # 󰖕
    desc="局部多云"
    ;;
3)
    curwea="" # 󰖐
    desc="阴天"
    ;;
45)
    curwea=" Wait! " # 󰖑
    desc="雾"
    ;;
48)
    curwea="" # 󰖑
    desc="沉积雾凇"
    ;;
51)
    curwea="" # 󰖗
    desc="轻微毛毛雨"
    ;;
53)
    curwea="" # 󰖗
    desc="中等毛毛雨"
    ;;
55)
    curwea="" # 󰖗
    desc="密集毛毛雨"
    ;;
56)
    curwea="" # 󰖗
    desc="轻微冻毛毛雨"
    ;;
57)
    curwea="" # 󰖗
    desc="密集冻毛毛雨"
    ;;
61)
    curwea="" # 󰙗
    desc="微雨"
    ;;
63)
    curwea="" # 󰙗
    desc="中雨"
    ;;
65)
    curwea="" # 󰙗
    desc="大雨"
    ;;
66)
    curwea="" # 󰙗
    desc="轻微冻雨"
    ;;
67)
    curwea="" # 󰙗
    desc="强冻雨"
    ;;
71)
    curwea="" # 󰼶
    desc="小雪"
    ;;
73)
    curwea="" # 󰼶
    desc="中雪"
    ;;
75)
    curwea="" # 󰼶 (大雪换用更密集的雪图标)
    ;;
77)
    curwea="" # 󰼶
    desc="雪米"
    ;;
80)
    curwea="" # 󰖖
    desc="阵雨"
    ;;
81)
    curwea="" # 󰖖
    desc="强阵雨"
    ;;
82)
    curwea="" # 󰖖
    desc="剧烈阵雨"
    ;;
85)
    curwea="" # 󰙿
    desc="阵雪"
    ;;
86)
    curwea="" # 󰙿
    desc="强阵雪"
    ;;
95)
    curwea="" # 󰙾
    desc="雷暴"
    ;;
96)
    curwea="" # 󰙾
    desc="雷暴伴有小冰雹"
    ;;
99)
    curwea="" # 󰙾
    desc="雷暴伴有大冰雹"
    ;;
*)
    curwea="" # 󰻂
    desc="未知状态 ($wea)"
    ;;
esac

# 输出 JSON 给 Waybar
echo "{\"text\": \"$curwea $tem°C\", \"tooltip\": \"$desc ($wea)\"}"
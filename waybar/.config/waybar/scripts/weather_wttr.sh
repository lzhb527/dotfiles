#!/bin/bash

# 配置：城市、语言、单位
CITY="Shuyang"
LANG="zh"
UNIT="m"

# 获取数据 (j1 代表 JSON, m 代表公制)
res=$(curl -s "wttr.in/$CITY?format=j1&${UNIT}&lang=${LANG}")

# 检查返回是否有效
if [ -z "$res" ] || [ "$(echo "$res" | jq -r '.current_condition')" == "null" ]; then
    echo '{"text": "   --°C", "tooltip": "天气服务不可用"}'
    exit 1
fi

# 提取核心数据 (current_condition 是个数组，取第0个)
temp=$(echo "$res" | jq -r '.current_condition[0].temp_C')
code=$(echo "$res" | jq -r '.current_condition[0].weatherCode')
feels=$(echo "$res" | jq -r '.current_condition[0].FeelsLikeC')
hum=$(echo "$res" | jq -r '.current_condition[0].humidity')

# 提取描述：优先取中文，没有则取默认描述
desc=$(echo "$res" | jq -r '.current_condition[0].lang_zh[0].value // .current_condition[0].weatherDesc[0].value')

# 完整代码映射与中文补全
case $code in
113)
    icon=""
    label="晴朗"
    ;;
116)
    icon="  "
    label="多云"
    ;;
119)
    icon="  "
    label="阴天"
    ;;
122)
    icon=""
    label="阴"
    ;;
143 | 248 | 260)
    icon=""
    label="有雾"
    ;;
176 | 263 | 266 | 293 | 296)
    icon=""
    label="轻微降雨"
    ;;
299 | 302 | 305 | 308)
    icon=""
    label="阵雨/大雨"
    ;;
311 | 314 | 317 | 350)
    icon=""
    label="冻雨"
    ;;
179 | 182 | 185 | 227 | 230 | 323 | 326 | 329 | 332 | 335 | 338 | 351)
    icon="  "
    label="降雪"
    ;;
353 | 356 | 359 | 362 | 365 | 368 | 371)
    icon=""
    label="阵雨/阵雪"
    ;;
200 | 386 | 389 | 392 | 395)
    icon=""
    label="雷暴"
    ;;
*)
    icon=""
    label="未知"
    ;;
esac

# 如果 API 返回的是英文 Sunny 等，用 label 替换它
if [[ "$desc" =~ [a-zA-Z] ]]; then
    display_desc=$label
else
    display_desc=$desc
fi

# 输出 Waybar JSON
echo "{\"text\": \"$icon $temp°C\", \"tooltip\": \"$display_desc 体感: ${feels}°C 湿度: ${hum}%\"}"

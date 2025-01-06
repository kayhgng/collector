#!/bin/bash

# آدرس API
url="https://shadowmere.akiel.dev/api/sub"

# جایگزین کردن بخش‌های هر کانفیگ
process_config() {
    config=$1
    # حذف هر چیزی بعد از #
    config=$(echo "$config" | cut -d'#' -f1)
    # جایگزینی با عبارت جدید
    config="${config} Github.com/kayhgng - KayH GNG"
    echo "$config"
}

# پینگ زدن به یک آدرس
ping_host() {
    host=$1
    ping_result=$(ping -c 1 "$host" 2>/dev/null | grep 'time=')
    if [ -z "$ping_result" ]; then
        echo "inf"
    else
        ping_time=$(echo "$ping_result" | sed -n 's/.*time=\([0-9.]*\) ms/\1/p')
        echo "$ping_time"
    fi
}

# ارسال درخواست GET به API و بررسی نتیجه
response=$(curl -s "$url")

# چک کردن وضعیت درخواست
if [ $? -ne 0 ]; then
    echo "Error fetching data from API"
    exit 1
fi

# نمایش محتوای پاسخ برای بررسی
echo "API response:"
echo "$response" | jq .

# ایجاد آرایه برای ذخیره اطلاعات کانفیگ‌ها و زمان پینگ
configs=()

# پردازش پاسخ JSON
echo "$response" | jq -r '.[] | .config' | while read -r config; do
    # استخراج host از config
    host=$(echo "$config" | cut -d' ' -f1)  # فرض بر این است که آدرس host در ابتدای هر کانفیگ است
    processed_config=$(process_config "$config")
    ping_time=$(ping_host "$host")
    
    # ذخیره کانفیگ و پینگ در آرایه
    configs+=("$ping_time|$processed_config")
done

# مرتب‌سازی کانفیگ‌ها بر اساس زمان پینگ
sorted_configs=$(for config in "${configs[@]}"; do
    echo "$config"
done | sort -n -t'|' -k1)

# ذخیره کردن به فایل JSON
output_file="configs_with_ping.json"
echo "[" > "$output_file"
first=true
while IFS="|" read -r ping_time config; do
    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> "$output_file"
    fi
    echo "  {" >> "$output_file"
    echo "    \"config\": \"$config\"," >> "$output_file"
    echo "    \"ping_time\": $ping_time" >> "$output_file"
    echo "  }" >> "$output_file"
done <<< "$sorted_configs"
echo "]" >> "$output_file"

echo "The configs have been processed and saved successfully to $output_file."

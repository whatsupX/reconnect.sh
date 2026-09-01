#!/bin/bash

# ==========================================
# กำหนดค่าสี (ANSI Colors)
# ==========================================
C_CYAN='\e[36m'
C_GREEN='\e[32m'
C_YELLOW='\e[33m'
C_RED='\e[31m'
C_PURPLE='\e[35m'
C_RESET='\e[0m'
CONFIG_FILE="roblox_accounts.cfg"
LUA_FILENAME="status_check.lua"

# ==========================================
# ฟังก์ชันแสดงส่วนหัว
# ==========================================
show_header() {
    echo -e "${C_CYAN}  _____ _  _   ___ ___ _  ___ ___ _  _ ${C_RESET}"
    echo -e "${C_CYAN} |_   _| || | | _ \ __| |/ _ \_ _| \| |${C_RESET}"
    echo -e "${C_CYAN}   | | | __ | |   / _|| | (_) | || .\` |${C_RESET}"
    echo -e "${C_CYAN}   |_| |_||_| |_|_\___|/ \___/___|_|\_|${C_RESET}"
    echo -e "${C_CYAN}                     |__/              ${C_RESET}"
    echo -e "${C_GREEN}       TOOL v6.1 (Smart Watchdog)      ${C_RESET}"
    echo -e "${C_YELLOW}          Made by whatsupX             ${C_RESET}"
    echo ""
}

# ==========================================
# เมนู 3: ระบบฝัง Lua Script (ระบบส่งชีพจร)
# ==========================================
setup_webhook() {
    clear
    show_header
    echo -e "${C_CYAN}--- Setup Discord Webhook & Autoexec ---${C_RESET}"
    read -p "🔗 กรุณาใส่ลิงก์ Discord Webhook: " webhook_url
    
    [[ -z "$webhook_url" ]] && return

    echo -e "${C_YELLOW}🔍 กำลังค้นหาโฟลเดอร์ Autoexec ทั้งหมดในเครื่อง...${C_RESET}"
    autoexec_folders=$(find /storage/emulated/0 -maxdepth 4 -type d -iname "Autoexec" 2>/dev/null)

    [[ -z "$autoexec_folders" ]] && return

    echo "$autoexec_folders" | while read -r folder; do
        lua_path="$folder/$LUA_FILENAME"
        [[ -f "$lua_path" ]] && rm "$lua_path"
        
        pkg_name=$(basename "$folder")

        cat <<EOF > "$lua_path"
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local webhookUrl = "$webhook_url"
local packageName = "$pkg_name"

local playerName = player and player.Name or "Unknown"
local displayName = player and player.DisplayName or "Unknown"

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

local function sendWebhook(title, desc, colorHex)
    if webhookUrl == "" or not httpRequest then return end
    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = desc,
            ["color"] = colorHex,
            ["fields"] = {
                {["name"] = "👤 Username", ["value"] = playerName, ["inline"] = true},
                {["name"] = "📱 Package", ["value"] = packageName, ["inline"] = true}
            },
            ["footer"] = {["text"] = "TH REJOIN TOOL"}
        }}
    }
    pcall(function()
        httpRequest({
            Url = webhookUrl, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

sendWebhook("✅ เข้าร่วมเซิร์ฟเวอร์สำเร็จ!", "**JobId:** \`" .. tostring(game.JobId) .. "\`", 65280)

GuiService.ErrorMessageChanged:Connect(function(errorMsg)
    if errorMsg and errorMsg ~= "" then 
        sendWebhook("❌ หลุดออกจากเกม!", "**สาเหตุ:** " .. errorMsg, 16711680) 
    end
end)

task.spawn(function()
    while task.wait(20) do
        pcall(function()
            writefile("ping_" .. packageName .. ".txt", playerName .. "|" .. tostring(os.time()))
        end)
    end
end)
EOF
        echo -e "${C_GREEN}✔️ เพิ่มไฟล์และระบบชีพจรลงใน: $folder สำเร็จ${C_RESET}"
    done
    read -p "กด Enter เพื่อกลับไปเมนูหลัก..."
}

# ==========================================
# เมนู 2: ระบบค้นหาจออัตโนมัติ
# ==========================================
start_auto_setup() {
    clear
    show_header
    echo -e "${C_CYAN}--- Automatic Setup (Detect Packages) ---${C_RESET}"
    echo -e "${C_YELLOW}🔄 ระบบกำลังค้นหาแพ็กเกจโคลนทั้งหมด...${C_RESET}"
    
    pm list packages | grep "roblox.clien" | cut -f 2 -d ':' > "$CONFIG_FILE"
    screen_count=$(wc -l < "$CONFIG_FILE")

    if [ "$screen_count" -gt 0 ]; then
        echo -e "${C_GREEN}✅ ตรวจพบและบันทึกอัตโนมัติจำนวน $screen_count จอ${C_RESET}"
        sleep 2
    else
        echo -e "${C_RED}❌ ไม่พบแพ็กเกจโคลนที่ขึ้นต้นด้วย 'roblox.clien'${C_RESET}"
        sleep 2
    fi
}

# ==========================================
# ระบบวาดตาราง Live Dashboard
# ==========================================
draw_dashboard() {
    clear
    show_header
    echo -e "${C_CYAN}--- 📊 Smart Watchdog Dashboard ---${C_RESET}"
    echo -e "▶️ สถานะระบบ: ${global_msg}"
    echo "================================================================="
    printf "| %-16s | %-16s | %-20s |\n" "📱 Package" "👤 Account" "📌 Status"
    echo "================================================================="
    
    for j in "${!pkgs[@]}"; do
        local pkg="${pkgs[$j]}"
        local acc="${accounts[$j]}"
        local stat="${statuses[$j]}"
        local col="${colors[$j]}"
        printf "| %-16s | %-16s | ${col}%-20s${C_RESET} |\n" "$pkg" "$acc" "$stat"
    done
    
    echo "================================================================="
    echo -e "${C_RED}[ กด Ctrl+C เพื่อหยุดการทำงาน ]${C_RESET}"
}

# ==========================================
# ฟังก์ชันเปิดจอเฉพาะแอปที่หลุด
# ==========================================
relaunch_pkg() {
    local p="$1"
    local idx="$2"
    
    statuses[$idx]="ล้างแคช..."
    colors[$idx]="$C_CYAN"
    draw_dashboard
    cache_path="/storage/emulated/0/Android/data/$p/cache"
    if [ -d "$cache_path" ]; then rm -rf "$cache_path"/* 2>/dev/null; fi

    statuses[$idx]="กำลังปิด (Kill)"
    colors[$idx]="$C_RED"
    draw_dashboard
    
    # ถอดคำสั่ง Home ออก ป้องกัน Termux เด้งพับหน้าจอ
    am force-stop "$p" > /dev/null 2>&1
    sleep 2

    statuses[$idx]="เปิดหน้าแรก"
    colors[$idx]="$C_GREEN"
    monkey -p "$p" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
    
    for (( w=5; w>0; w-- )); do
        statuses[$idx]="รอเข้าเกม ${w}s..."
        draw_dashboard
        sleep 1
    done
    
    statuses[$idx]="ส่งเข้าแมพ (Map)"
    draw_dashboard
    am start -f 0x10000000 -a android.intent.action.VIEW -d "roblox://placeId=$place_id" -p "$p" > /dev/null 2>&1
    
    launch_times[$idx]=$(date +%s)
    if [ -n "${ping_paths[$idx]}" ] && [ -f "${ping_paths[$idx]}" ]; then
        rm "${ping_paths[$idx]}" 2>/dev/null
    fi
    
    statuses[$idx]="กำลังโหลด (Loading)"
    colors[$idx]="$C_YELLOW"
}

# ==========================================
# เมนู 1: ระบบ Rejoin (Watchdog Loop)
# ==========================================
start_auto_rejoin() {
    clear
    show_header
    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
        echo -e "${C_RED}❌ ไม่พบข้อมูลจอ! กรุณาไปทำ Auto Setup (เมนู 2) ก่อน${C_RESET}"
        sleep 3
        return
    fi

    echo -e "${C_CYAN}--- Auto Rejoin Setup ---${C_RESET}"
    read -p "🎯 Enter Place ID: " place_id
    [[ -z "$place_id" ]] && return

    read -p "⏳ หน่วงเวลาระหว่างเปิดจอรอบแรกกี่วินาที? (แนะนำ 5-10): " delay_between
    [[ ! "$delay_between" =~ ^[0-9]+$ ]] && delay_between=7

    pkgs=()
    while IFS= read -r line; do [[ -n "$line" ]] && pkgs+=("$line"); done < "$CONFIG_FILE"
    
    statuses=()
    colors=()
    accounts=()
    ping_paths=()
    launch_times=()

    tput civis 

    global_msg="${C_GREEN}🚀 กำลังรันเปิดจอทั้งหมดในรอบแรก...${C_RESET}"
    for i in "${!pkgs[@]}"; do
        accounts[$i]="กำลังโหลด..."
        relaunch_pkg "${pkgs[$i]}" "$i"
        sleep "$delay_between"
    done

    while true; do
        global_msg="${C_CYAN}👀 ระบบ Watchdog กำลังตรวจสอบการตอบสนอง...${C_RESET}"
        current_time=$(date +%s)

        for i in "${!pkgs[@]}"; do
            pkg="${pkgs[$i]}"
            
            if [ -z "${ping_paths[$i]}" ]; then
                found_path=$(find /storage/emulated/0 -maxdepth 5 -type f -name "ping_${pkg}.txt" 2>/dev/null | head -n 1)
                if [ -n "$found_path" ]; then
                    ping_paths[$i]="$found_path"
                fi
            fi

            if [ -n "${ping_paths[$i]}" ] && [ -f "${ping_paths[$i]}" ]; then
                content=$(cat "${ping_paths[$i]}" 2>/dev/null)
                acc_name=$(echo "$content" | cut -d'|' -f1)
                last_ping=$(echo "$content" | cut -d'|' -f2)
                
                if [[ -n "$last_ping" && "$last_ping" =~ ^[0-9]+$ ]]; then
                    diff=$((current_time - last_ping))
                    accounts[$i]="$acc_name"

                    if [ $diff -gt 60 ]; then
                        statuses[$i]="หลุด! (Dead > 60s)"
                        colors[$i]="$C_RED"
                        draw_dashboard
                        relaunch_pkg "$pkg" "$i"
                    else
                        statuses[$i]="ออนไลน์ (${diff}s ก่อน)"
                        colors[$i]="$C_GREEN"
                    fi
                fi
            else
                launched_at=${launch_times[$i]:-0}
                wait_time=$((current_time - launched_at))
                
                if [ $wait_time -gt 150 ]; then 
                    statuses[$i]="จอค้าง! (Timeout)"
                    colors[$i]="$C_RED"
                    draw_dashboard
                    relaunch_pkg "$pkg" "$i"
                else
                    statuses[$i]="รอสคริปต์ทำงาน (${wait_time}s)"
                    colors[$i]="$C_YELLOW"
                fi
            fi
        done
        
        draw_dashboard
        sleep 5
    done
    
    tput cnorm 
}

# ==========================================
# ดักจับ Ctrl+C เพื่อคืนค่า Cursor
# ==========================================
trap 'tput cnorm; clear; exit' INT

# ==========================================
# เมนูหลัก (Main Menu)
# ==========================================
while true; do
    clear
    show_header
    echo -e "${C_CYAN}Available Features:${C_RESET}"
    echo -e "${C_CYAN}1.${C_RESET} Start Auto Rejoin (Smart Watchdog)"
    echo -e "${C_CYAN}2.${C_RESET} Start Auto Setup (Detect Packages)"
    echo -e "${C_CYAN}3.${C_RESET} Add Discord Webhook & Heartbeat to Autoexec"
    echo -e "${C_CYAN}0.${C_RESET} Exit"
    echo ""
    read -p "Select an option: " opt_main

    case $opt_main in
        1) start_auto_rejoin ;;
        2) start_auto_setup ;;
        3) setup_webhook ;;
        0) clear; tput cnorm; exit 0 ;;
        *) echo -e "${C_RED}Invalid option!${C_RESET}"; sleep 1 ;;
    esac
done

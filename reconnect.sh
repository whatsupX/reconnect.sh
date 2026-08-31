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
    echo -e "${C_CYAN} _ __ ___  ___ ___  _ __  _ __   ___  ___| |_${C_RESET}"
    echo -e "${C_CYAN}| '__/ _ \/ __/ _ \| '_ \| '_ \ / _ \/ __| __|${C_RESET}"
    echo -e "${C_CYAN}| | |  __/ (_| (_) | | | | | | |  __/ (__| |_${C_RESET}"
    echo -e "${C_CYAN}|_|  \___|\___\___/|_| |_|_| |_|\___|\___|\__|${C_RESET}"
    echo "              Made for Multi-Account v4.3"
    echo ""
}

# ==========================================
# เมนู 3: ระบบฝัง Lua Script
# ==========================================
setup_webhook() {
    clear
    show_header
    echo -e "${C_CYAN}--- Setup Discord Webhook & Autoexec ---${C_RESET}"
    read -p "🔗 กรุณาใส่ลิงก์ Discord Webhook: " webhook_url
    
    [[ -z "$webhook_url" ]] && return

    echo -e "${C_YELLOW}🔍 กำลังค้นหาโฟลเดอร์ Autoexec ทั้งหมดในเครื่อง...${C_RESET}"
    autoexec_folders=$(find /storage/emulated/0 -maxdepth 3 -type d -iname "Autoexec" 2>/dev/null)

    [[ -z "$autoexec_folders" ]] && return

    echo "$autoexec_folders" | while read -r folder; do
        lua_path="$folder/$LUA_FILENAME"
        [[ -f "$lua_path" ]] && rm "$lua_path"

        cat <<EOF > "$lua_path"
repeat wait() until game:IsLoaded()
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local webhookUrl = "$webhook_url"

local playerName = player and player.Name or "กำลังโหลด..."
local displayName = player and player.DisplayName or "กำลังโหลด..."

local function sendWebhook(title, desc, colorHex)
    if webhookUrl == "" or not request then return end
    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = desc,
            ["color"] = colorHex,
            ["fields"] = {
                {["name"] = "👤 Username", ["value"] = playerName, ["inline"] = true},
                {["name"] = "🏷️ Display Name", ["value"] = displayName, ["inline"] = true}
            },
            ["footer"] = {["text"] = "Auto Rejoin System"}
        }}
    }
    pcall(function()
        request({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data)})
    end)
end

sendWebhook("✅ เข้าร่วมเซิร์ฟเวอร์สำเร็จ!", "**JobId:** \`" .. tostring(game.JobId) .. "\`", 65280)
GuiService.ErrorMessageChanged:Connect(function(errorMsg)
    if errorMsg and errorMsg ~= "" then sendWebhook("❌ หลุดออกจากเกม!", "**สาเหตุ:** " .. errorMsg, 16711680) end
end)
EOF
        echo -e "${C_GREEN}✔️ เพิ่มไฟล์ลงใน: $folder สำเร็จ${C_RESET}"
    done
    read -p "กด Enter เพื่อกลับไปเมนูหลัก..."
}

# ==========================================
# เมนู 2: ระบบค้นหาจออัตโนมัติ (Auto Setup)
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
    echo -e "${C_CYAN}--- 📊 Live Rejoin Dashboard ---${C_RESET}"
    echo -e "▶️ สถานะระบบ: ${global_msg}"
    echo "================================================================"
    printf "| %-16s | %-16s | %-18s |\n" "📱 Package Name" "📌 Status" "ℹ️ Info"
    echo "================================================================"
    
    for j in "${!pkgs[@]}"; do
        local pkg="${pkgs[$j]}"
        local stat="${statuses[$j]}"
        local col="${colors[$j]}"
        local info="${infos[$j]}"
        printf "| %-16s | ${col}%-16s${C_RESET} | %-18s |\n" "$pkg" "$stat" "$info"
    done
    
    echo "================================================================"
    echo -e "${C_RED}[ กด Ctrl+C เพื่อหยุดการทำงาน ]${C_RESET}"
}

# ==========================================
# เมนู 1: ระบบ Rejoin 
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

    read -p "⏱️ หน่วงเวลาก่อนเริ่ม Rejoin รอบใหม่ (เช่น 600 วินาที): " delay_time
    [[ ! "$delay_time" =~ ^[0-9]+$ ]] && delay_time=600

    read -p "⏳ หน่วงเวลาระหว่างเปิดแต่ละจอกี่วินาที? (แนะนำ 5-10): " delay_between
    [[ ! "$delay_between" =~ ^[0-9]+$ ]] && delay_between=7

    pkgs=()
    while IFS= read -r line; do [[ -n "$line" ]] && pkgs+=("$line"); done < "$CONFIG_FILE"
    
    statuses=()
    colors=()
    infos=()

    tput civis 

    while true; do
        for i in "${!pkgs[@]}"; do
            statuses[$i]="รอคิว (Waiting)"
            colors[$i]="$C_YELLOW"
            infos[$i]="-"
        done
        
        global_msg="${C_CYAN}🧹 กำลังเคลียร์แคชไฟล์ขยะ...${C_RESET}"
        
        for i in "${!pkgs[@]}"; do
            statuses[$i]="ล้างแคช (Cache)"
            colors[$i]="$C_CYAN"
            infos[$i]="ลบไฟล์ขยะ..."
            draw_dashboard
            
            cache_path="/storage/emulated/0/Android/data/${pkgs[$i]}/cache"
            if [ -d "$cache_path" ]; then rm -rf "$cache_path"/* 2>/dev/null; fi
        done

        global_msg="${C_GREEN}🚀 กำลังรันระบบเปิดจอ...${C_RESET}"

        for i in "${!pkgs[@]}"; do
            statuses[$i]="กำลังปิด (Kill)"
            colors[$i]="$C_RED"
            infos[$i]="Force Stop"
            draw_dashboard
            
            # --- แก้ไขระบบ Kill ให้เคลียร์จอ ---
            input keyevent 3  # กดปุ่ม Home เพื่อพับหน้าจอลงไปก่อน
            sleep 1
            am force-stop "${pkgs[$i]}" > /dev/null 2>&1
            sleep 2
            # --------------------------------
            
            statuses[$i]="เปิดหน้าแรก"
            colors[$i]="$C_GREEN"
            monkey -p "${pkgs[$i]}" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
            
            for (( w=3; w>0; w-- )); do
                infos[$i]="รอเข้าเกม ${w}s..."
                draw_dashboard
                sleep 1
            done
            
            statuses[$i]="ส่งเข้าแมพ (Map)"
            infos[$i]="Place ID"
            draw_dashboard
            am start -a android.intent.action.VIEW -d "roblox://placeId=$place_id" -p "${pkgs[$i]}" > /dev/null 2>&1
            
            statuses[$i]="รันปกติ (Running)"
            colors[$i]="$C_PURPLE"
            
            for (( w=$delay_between; w>0; w-- )); do
                infos[$i]="พักเครื่อง ${w}s..."
                draw_dashboard
                sleep 1
            done
            infos[$i]="- ปกติ -"
            draw_dashboard
        done

        for (( w=$delay_time; w>0; w-- )); do
            global_msg="รอรอบถัดไปใน: ${C_YELLOW}${w} วินาที${C_RESET}"
            draw_dashboard
            sleep 1
        done
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
    echo -e "${C_CYAN}1.${C_RESET} Start Auto Rejoin (Live Dashboard)"
    echo -e "${C_CYAN}2.${C_RESET} Start Auto Setup (Detect Packages)"
    echo -e "${C_CYAN}3.${C_RESET} Add Discord Webhook to Autoexec"
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

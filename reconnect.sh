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
    clear
    echo -e "${C_CYAN}"
    echo " _ __ ___  ___ ___  _ __  _ __   ___  ___| |_"
    echo "| '__/ _ \/ __/ _ \| '_ \| '_ \ / _ \/ __| __|"
    echo "| | |  __/ (_| (_) | | | | | | |  __/ (__| |_"
    echo "|_|  \___|\___\___/|_| |_|_| |_|\___|\___|\__|"
    echo "              Made for Multi-Account v3.1"
    echo -e "${C_RESET}"
}

# ==========================================
# เมนู 3: ระบบฝัง Lua Script ไปยังโฟลเดอร์ Autoexec
# ==========================================
setup_webhook() {
    show_header
    echo -e "${C_CYAN}--- Setup Discord Webhook & Autoexec ---${C_RESET}"
    read -p "🔗 กรุณาใส่ลิงก์ Discord Webhook: " webhook_url
    
    if [ -z "$webhook_url" ]; then
        echo -e "${C_RED}❌ ข้อผิดพลาด: ไม่ได้ใส่ลิงก์ Webhook!${C_RESET}"
        sleep 2
        return
    fi

    echo -e "${C_YELLOW}🔍 กำลังค้นหาโฟลเดอร์ Autoexec ทั้งหมดในเครื่อง...${C_RESET}"
    autoexec_folders=$(find /storage/emulated/0 -maxdepth 3 -type d -iname "Autoexec" 2>/dev/null)

    if [ -z "$autoexec_folders" ]; then
        echo -e "${C_RED}❌ ไม่พบโฟลเดอร์ Autoexec ในเครื่อง${C_RESET}"
        sleep 3
        return
    fi

    echo "$autoexec_folders" | while read -r folder; do
        lua_path="$folder/$LUA_FILENAME"
        
        if [ -f "$lua_path" ]; then
            rm "$lua_path"
        fi

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
        request({
            Url = webhookUrl,
            Method = "POST",
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
EOF
        echo -e "${C_GREEN}✔️ เพิ่มไฟล์ลงใน: $folder สำเร็จ${C_RESET}"
    done

    echo -e "${C_CYAN}🎉 ติดตั้ง Webhook พร้อมระบบแยกบัญชีเรียบร้อยแล้ว!${C_RESET}"
    read -p "กด Enter เพื่อกลับไปเมนูหลัก..."
}

# ==========================================
# เมนู 2: ระบบค้นหาจออัตโนมัติ (Auto Setup)
# ==========================================
start_auto_setup() {
    show_header
    echo -e "${C_CYAN}--- Automatic Setup (Detect Packages) ---${C_RESET}"
    echo -e "${C_YELLOW}🔄 ระบบกำลังค้นหาแพ็กเกจโคลนทั้งหมด...${C_RESET}"
    
    pm list packages | grep "roblox.clien" | cut -f 2 -d ':' > "$CONFIG_FILE"
    screen_count=$(wc -l < "$CONFIG_FILE")

    if [ "$screen_count" -gt 0 ]; then
        echo -e "${C_GREEN}✅ ตรวจพบและบันทึกอัตโนมัติจำนวน $screen_count จอ ดังนี้:${C_RESET}"
        cat "$CONFIG_FILE" | while read -r pkg; do
            echo -e "   - $pkg"
        done
        echo ""
        echo -e "${C_GREEN}🎉 บันทึกข้อมูลสำเร็จ! ไปที่เมนู Auto Rejoin ได้เลย${C_RESET}"
    else
        echo -e "${C_RED}❌ ไม่พบแพ็กเกจโคลนที่ขึ้นต้นด้วย 'roblox.clien'${C_RESET}"
    fi
    sleep 4
}

# ==========================================
# เมนู 1: ระบบ Rejoin (เพิ่มระบบ Clear Cache)
# ==========================================
start_auto_rejoin() {
    show_header
    
    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
        echo -e "${C_RED}❌ ไม่พบข้อมูลจอ! กรุณาไปทำ Auto Setup (เมนู 2) ก่อน${C_RESET}"
        sleep 3
        return
    fi

    echo -e "${C_CYAN}--- Auto Rejoin Setup ---${C_RESET}"
    read -p "🎯 Enter Place ID: " place_id
    if [ -z "$place_id" ]; then
        echo -e "${C_RED}❌ Error: Place ID is required!${C_RESET}"
        sleep 2
        return
    fi

    read -p "⏱️ หน่วงเวลาก่อนเริ่ม Rejoin รอบใหม่ (เช่น 600 วินาที): " delay_time
    if ! [[ "$delay_time" =~ ^[0-9]+$ ]]; then delay_time=600; fi

    read -p "⏳ หน่วงเวลาระหว่างเปิดแต่ละจอกี่วินาที? (แนะนำ 5-10): " delay_between
    if ! [[ "$delay_between" =~ ^[0-9]+$ ]]; then delay_between=7; fi

    echo -e "${C_GREEN}✅ Auto Rejoin เริ่มทำงาน! (กด Ctrl+C เพื่อหยุด)${C_RESET}"
    sleep 2

    while true; do
        current_time=$(date +"%H:%M:%S")
        show_header
        echo -e "${C_CYAN}[$current_time] 🔄 กำลังดำเนินการรันทั้งหมด...${C_RESET}"
        echo "============================================================"
        
        # --- ระบบล้างแคชก่อนเปิดเกม ---
        echo -e "${C_YELLOW}🧹 ล้างไฟล์ขยะ (Cache) เพื่อลดอาการเด้งหลุด...${C_RESET}"
        while IFS= read -r pkg || [ -n "$pkg" ]; do
            cache_path="/storage/emulated/0/Android/data/$pkg/cache"
            if [ -d "$cache_path" ]; then
                rm -rf "$cache_path"/* 2>/dev/null
            fi
        done < "$CONFIG_FILE"
        echo -e "${C_GREEN}✅ ล้างแคชสำเร็จ!${C_RESET}"
        echo "------------------------------------------------------------"
        
        while IFS= read -r pkg || [ -n "$pkg" ]; do
            echo -e "${C_YELLOW}🛑 Killing process: $pkg...${C_RESET}"
            am force-stop "$pkg" > /dev/null 2>&1
            sleep 2
            
            echo -e "${C_GREEN}🚀 Launching: $pkg...${C_RESET}"
            am start -a android.intent.action.VIEW -d "roblox://placeId=$place_id" -p "$pkg" > /dev/null 2>&1
            
            echo -e "${C_CYAN}✅ ส่งคำสั่งเปิดจอสำเร็จ!${C_RESET}"
            echo -e "${C_PURPLE}💤 พักเครื่อง $delay_between วินาที ก่อนเปิดจอถัดไป...${C_RESET}"
            sleep "$delay_between"
            
        done < "$CONFIG_FILE"

        echo "============================================================"
        echo -e "${C_CYAN}⏳ รอ $delay_time วินาทีเพื่อเริ่ม Rejoin รอบใหม่...${C_RESET}"
        sleep "$delay_time"
    done
}

# ==========================================
# เมนูหลัก (Main Menu)
# ==========================================
while true; do
    show_header
    echo -e "${C_CYAN}Available Features:${C_RESET}"
    echo -e "${C_CYAN}1.${C_RESET} Start Auto Rejoin (Multi-Account & Auto Clear Cache)"
    echo -e "${C_CYAN}2.${C_RESET} Start Auto Setup (Detect Packages)"
    echo -e "${C_CYAN}3.${C_RESET} Add Discord Webhook to Autoexec"
    echo -e "${C_CYAN}0.${C_RESET} Exit"
    echo ""
    read -p "Select an option: " opt_main

    case $opt_main in
        1) start_auto_rejoin ;;
        2) start_auto_setup ;;
        3) setup_webhook ;;
        0) clear; exit 0 ;;
        *) echo -e "${C_RED}Invalid option!${C_RESET}"; sleep 1 ;;
    esac
done

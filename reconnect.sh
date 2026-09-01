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
    echo -e "${C_GREEN}    TOOL v6.8 (Root Checker)           ${C_RESET}"
    echo -e "${C_YELLOW}          Made by whatsupX             ${C_RESET}"
    echo ""
}

# ==========================================
# ระบบตรวจสอบสิทธิ์ Root
# ==========================================
check_root() {
    clear
    show_header
    echo -e "${C_CYAN}🔍 กำลังตรวจสอบสิทธิ์ Root ในเครื่อง...${C_RESET}"
    
    # ลองรันคำสั่งด้วย su เพื่อเช็คว่ามีสิทธิ์ Root หรือไม่
    if ! su -c 'true' > /dev/null 2>&1; then
        echo -e "${C_RED}❌ ตรวจพบว่าเครื่องของคุณยังไม่ได้ Root! หรือยังไม่ได้อนุญาตสิทธิ์ให้ Termux${C_RESET}"
        echo -e "${C_YELLOW}⚠️ กรุณาไปเปิดใช้งาน Root ในการตั้งค่าของ Cloud Phone หรือกด Grant (อนุญาต) สิทธิ์ก่อนใช้งาน${C_RESET}"
        echo ""
        exit 1
    else
        echo -e "${C_GREEN}✅ ตรวจพบสิทธิ์ Root เรียบร้อยแล้ว! พร้อมใช้งาน${C_RESET}"
        sleep 2
    fi
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
    autoexec_folders=$(find /storage/emulated/0 -maxdepth 4 -type d -iname "Autoexec" 2>/dev/null)

    if [ -z "$autoexec_folders" ]; then
        echo -e "${C_RED}❌ ไม่พบโฟลเดอร์ Autoexec ในเครื่อง${C_RESET}"
        sleep 3
        return
    fi

    echo "$autoexec_folders" | while read -r folder; do
        lua_path="$folder/$LUA_FILENAME"
        [[ -f "$lua_path" ]] && rm "$lua_path"
        
        cat <<EOF > "$lua_path"
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local webhookUrl = "$webhook_url"
local playerName = player and player.Name or "Unknown"
local displayName = player and player.DisplayName or "Unknown"
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

local function sendWebhook(title, desc, colorHex)
    if webhookUrl == "" or not httpRequest then return end
    local data = {
        ["embeds"] = {{
            ["title"] = title, ["description"] = desc, ["color"] = colorHex,
            ["fields"] = {
                {["name"] = "👤 Username", ["value"] = playerName, ["inline"] = true},
                {["name"] = "🏷️ Display Name", ["value"] = displayName, ["inline"] = true}
            },
            ["footer"] = {["text"] = "TH REJOIN TOOL"}
        }}
    }
    pcall(function() httpRequest({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data)}) end)
end

sendWebhook("✅ เข้าร่วมเซิร์ฟเวอร์สำเร็จ!", "**JobId:** \`" .. tostring(game.JobId) .. "\`", 65280)
GuiService.ErrorMessageChanged:Connect(function(errorMsg)
    if errorMsg and errorMsg ~= "" then sendWebhook("❌ หลุดออกจากเกม!", "**สาเหตุ:** " .. errorMsg, 16711680) end
end)

task.spawn(function()
    while task.wait(10) do
        pcall(function() writefile("ping_" .. playerName .. ".txt", tostring(os.time())) end)
    end
end)
EOF
        echo -e "${C_GREEN}✔️ เพิ่มไฟล์ระบบชีพจรแบบ Universal ลงใน: $folder สำเร็จ${C_RESET}"
    done
    echo ""
    read -p "กด Enter เพื่อกลับไปเมนูหลัก..."
}

# ==========================================
# เมนู 2: ระบบค้นหาจออัตโนมัติ
# ==========================================
start_auto_setup() {
    clear
    show_header
    echo -e "${C_CYAN}--- Automatic Setup (Detect Packages & Bind Accounts) ---${C_RESET}"
    echo -e "${C_YELLOW}🔄 ระบบกำลังค้นหาแพ็กเกจโคลนทั้งหมด...${C_RESET}"
    
    su -c "pm list packages" | grep "roblox.clien" | cut -f 2 -d ':' > "temp_pkg.txt"
    screen_count=$(wc -l < "temp_pkg.txt")

    if [ "$screen_count" -gt 0 ]; then
        echo -e "${C_GREEN}✅ ตรวจพบ $screen_count จอ!${C_RESET}"
        echo -e "${C_YELLOW}⚠️ เพื่อให้ Watchdog ทำงานได้ กรุณาใส่ Username ให้ตรงกับแต่ละจอ${C_RESET}"
        
        local found_pkgs=()
        while IFS= read -r line; do [[ -n "$line" ]] && found_pkgs+=("$line"); done < "temp_pkg.txt"
        
        > "$CONFIG_FILE"
        for pkg in "${found_pkgs[@]}"; do
            read -p "👤 ใส่ Username ของจอ [$pkg]: " uname
            [[ -z "$uname" ]] && uname="Unknown"
            echo "$pkg|$uname" >> "$CONFIG_FILE"
        done
        rm "temp_pkg.txt"
        echo -e "${C_GREEN}🎉 บันทึกข้อมูลและผูกบัญชีสำเร็จ!${C_RESET}"
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
        local acc="${unames[$j]}"
        local stat="${statuses[$j]}"
        local col="${colors[$j]}"
        printf "| %-16s | %-16s | ${col}%-20s${C_RESET} |\n" "$pkg" "$acc" "$stat"
    done
    echo "================================================================="
    echo -e "${C_RED}[ กด Ctrl+C เพื่อหยุดการทำงาน ]${C_RESET}"
}

# ==========================================
# ฟังก์ชันเปิดจอเฉพาะแอปที่หลุด (Ultimate Kill Bypass)
# ==========================================
relaunch_pkg() {
    local p="$1"
    local idx="$2"
    
    statuses[$idx]="ล้างแคช..."
    colors[$idx]="$C_CYAN"
    draw_dashboard
    cache_path="/storage/emulated/0/Android/data/$p/cache"
    if [ -d "$cache_path" ]; then su -c "rm -rf $cache_path/*" 2>/dev/null; fi

    statuses[$idx]="กำลังปิด (Kill)"
    colors[$idx]="$C_RED"
    draw_dashboard
    
    # 💥 โจมตีทะลวงฟองสบู่ด้วย Root
    su -c "am force-stop $p" > /dev/null 2>&1
    su -c "am force-stop --user all $p" > /dev/null 2>&1
    sleep 2

    statuses[$idx]="เปิดหน้าแรก"
    colors[$idx]="$C_GREEN"
    
    su -c "monkey -p \"$p\" -c android.intent.category.LAUNCHER 1" > /dev/null 2>&1
    
    for (( w=5; w>0; w-- )); do
        statuses[$idx]="รอเข้าเกม ${w}s..."
        draw_dashboard
        sleep 1
    done
    
    statuses[$idx]="ส่งเข้าแมพ (Map)"
    draw_dashboard
    
    su -c "am start -f 0x10000000 -a android.intent.action.VIEW -d \"roblox://placeId=$place_id\" -p \"$p\"" > /dev/null 2>&1
    
    launch_times[$idx]=$(date +%s)
    if [ -n "${ping_paths[$idx]}" ] && [ -f "${ping_paths[$idx]}" ]; then
        su -c "rm \"${ping_paths[$idx]}\"" 2>/dev/null
    fi
    ping_paths[$idx]=""
    
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
    unames=()
    while IFS='|' read -r pkg uname; do 
        if [[ -n "$pkg" && -n "$uname" ]]; then
            pkgs+=("$pkg")
            unames+=("$uname")
        fi
    done < "$CONFIG_FILE"
    
    statuses=()
    colors=()
    ping_paths=()
    launch_times=()

    tput civis 

    global_msg="${C_GREEN}🚀 กำลังรันเปิดจอทั้งหมดในรอบแรก...${C_RESET}"
    for i in "${!pkgs[@]}"; do
        relaunch_pkg "${pkgs[$i]}" "$i"
        sleep "$delay_between"
    done

    while true; do
        global_msg="${C_CYAN}👀 ระบบ Watchdog กำลังตรวจสอบการตอบสนอง...${C_RESET}"
        current_time=$(date +%s)

        for i in "${!pkgs[@]}"; do
            pkg="${pkgs[$i]}"
            uname="${unames[$i]}"
            
            if [ -z "${ping_paths[$i]}" ] || [ ! -f "${ping_paths[$i]}" ]; then
                found_path=$(find /storage/emulated/0 -maxdepth 5 -type f -name "ping_${uname}.txt" 2>/dev/null | head -n 1)
                if [ -n "$found_path" ]; then ping_paths[$i]="$found_path"; fi
            fi

            if [ -n "${ping_paths[$i]}" ] && [ -f "${ping_paths[$i]}" ]; then
                last_ping=$(cat "${ping_paths[$i]}" 2>/dev/null)
                if [[ "$last_ping" =~ ^[0-9]+$ ]]; then
                    diff=$((current_time - last_ping))
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
# เริ่มต้นการทำงาน (ตรวจสอบ Root ก่อนเลย)
# ==========================================
check_root

# ==========================================
# เมนูหลัก (Main Menu)
# ==========================================
while true; do
    clear
    show_header
    echo -e "${C_CYAN}Available Features:${C_RESET}"
    echo -e "${C_CYAN}1.${C_RESET} Start Auto Rejoin (Smart Watchdog)"
    echo -e "${C_CYAN}2.${C_RESET} Start Auto Setup (Detect Packages & Bind Accounts)"
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

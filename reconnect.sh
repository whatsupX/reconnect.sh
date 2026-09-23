#!/bin/bash

# ==========================================
# กำหนดค่าสี (ใช้ \033 แทน \e เพื่อป้องกันบั๊กหน้าจอ)
# ==========================================
C_CYAN='\033[36m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_RED='\033[31m'
C_PURPLE='\033[35m'
C_RESET='\033[0m'
CONFIG_FILE="roblox_accounts.cfg"
LUA_FILENAME="status_check.lua"

# ==========================================
# ฟังก์ชันแสดงส่วนหัว
# ==========================================
show_header() {
    echo -e "${C_CYAN}  _____ _  _   ___ ___ _  ___ ___ _  _ ${C_RESET}"
    echo -e "${C_CYAN} |_   _| || | | _ \ __| |/ _ \_ _| \| |${C_RESET}"
    echo -e "${C_CYAN}   | | | __ | |   / _|| | (_) | || .\` |${C_RESET}"
    echo -e "${C_CYAN}   \vert{}_\vert{} \vert{}_\vert{}\vert{}_\vert{} \vert{}_\vert{}_\___\vert{}/ \___/___\vert{}_\vert{}\_\vert{}${C_RESET}"
    echo -e "${C_CYAN}                     \vert{}__/${C_RESET}"
    echo -e "${C_GREEN}              TOOL v7.6${C_RESET}"
    echo -e "${C_YELLOW}          Made by whatsupX${C_RESET}"
    echo ""
}

# ==========================================
# ฟังก์ชันรันคำสั่ง Root แบบปลอดภัยขั้นสุด (< /dev/null ป้องกันจอรวน)
# ==========================================
safe_su() {
    su -c "$1" < /dev/null > /dev/null 2>&1
    stty onlcr sane 2>/dev/null
}

# ==========================================
# ระบบตรวจสอบสิทธิ์ Root
# ==========================================
check_root() {
    stty onlcr sane 2>/dev/null
    clear
    show_header
    echo -e "${C_CYAN}🔍 กำลังตรวจสอบสิทธิ์ Root ในเครื่อง...${C_RESET}"
    
    if ! su -c 'true' < /dev/null > /dev/null 2>&1; then
        echo -e "${C_RED}❌ ตรวจพบว่าเครื่องของคุณยังไม่ได้ Root! หรือยังไม่ได้อนุญาตสิทธิ์ให้ Termux${C_RESET}"
        echo -e "${C_YELLOW}⚠️ กรุณาไปเปิดใช้งาน Root ในการตั้งค่าของ Cloud Phone หรือกด Grant (อนุญาต) สิทธิ์ก่อนใช้งาน${C_RESET}"
        echo ""
        exit 1
    else
        echo -e "${C_GREEN}✅ ตรวจพบสิทธิ์ Root เรียบร้อยแล้ว! พร้อมใช้งาน${C_RESET}"
        sleep 1
    fi
    stty onlcr sane 2>/dev/null
}

# ==========================================
# เมนู 3: ระบบฝัง Lua Script
# ==========================================
setup_webhook() {
    clear
    show_header
    echo -e "${C_CYAN}--- Setup Discord Webhook & Autoexec ---${C_RESET}"
    echo -e "${C_YELLOW}[ กด Enter โดยไม่พิมพ์อะไร เพื่อยกเลิกและกลับเมนูหลัก ]${C_RESET}"
    
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
        echo -e "${C_GREEN}✔️ เพิ่มไฟล์ระบบชีพจรลงใน: $folder สำเร็จ${C_RESET}"
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
    
    if [ -s "$CONFIG_FILE" ]; then
        echo -e "${C_YELLOW}⚠️ พบข้อมูลหน้าจอและบัญชีที่เคยบันทึกไว้แล้ว!${C_RESET}"
        read -p "❓ ต้องการเคลียร์ข้อมูลและตั้งค่าใหม่หรือไม่? (y/n) [กด Enter เพื่อยกเลิก]: " confirm_reset
        if [[ "$confirm_reset" != "y" && "$confirm_reset" != "Y" ]]; then
            echo -e "${C_GREEN}✅ ยกเลิกการตั้งค่า (ยังคงใช้ข้อมูลบัญชีเดิม)${C_RESET}"
            sleep 2
            return
        fi
    fi

    echo -e "${C_YELLOW}🔄 ระบบกำลังค้นหาแพ็กเกจโคลนทั้งหมด...${C_RESET}"
    
    pm list packages | grep -i "roblox.clien" | cut -f 2 -d ':' > "temp_pkg.txt"
    stty onlcr sane 2>/dev/null
    screen_count=$(wc -l < "temp_pkg.txt")

    if [ "$screen_count" -eq 0 ]; then
        echo -e "${C_RED}❌ ไม่พบแพ็กเกจที่ชื่อ 'roblox.clien'${C_RESET}"
        read -p "🔍 กรุณาพิมพ์ชื่อแอป (หรือคำย่อ เช่น roblox, arceus) เพื่อค้นหาใหม่: " custom_pkg
        
        if [ -n "$custom_pkg" ]; then
            echo -e "${C_YELLOW}🔄 กำลังค้นหาแพ็กเกจที่มีคำว่า '$custom_pkg'...${C_RESET}"
            pm list packages | grep -i "$custom_pkg" | cut -f 2 -d ':' > "temp_pkg.txt"
            stty onlcr sane 2>/dev/null
            screen_count=$(wc -l < "temp_pkg.txt")
        fi
    fi

    if [ "$screen_count" -gt 0 ]; then
        echo -e "${C_GREEN}✅ ตรวจพบ $screen_count จอ!${C_RESET}"
        echo -e "${C_YELLOW}⚠️ เพื่อให้ระบบ Rejoin ทำงานได้ กรุณาใส่ Username ให้ตรงกับแต่ละจอ${C_RESET}"
        echo ""
        
        local found_pkgs=()
        while IFS= read -r line; do [[ -n "$line" ]] && found_pkgs+=("$line"); done < "temp_pkg.txt"
        
        local input_data=()
        for pkg in "${found_pkgs[@]}"; do
            read -p "👤 ใส่ Username ของจอ [$pkg]: " uname
            [[ -z "$uname" ]] && uname="Unknown"
            input_data+=("$pkg\vert{}$uname")
        done
        
        > "$CONFIG_FILE"
        for data in "${input_data[@]}"; do
            echo "$data" >> "$CONFIG_FILE"
        done
        
        rm "temp_pkg.txt" 2>/dev/null
        echo -e "\n${C_GREEN}🎉 บันทึกข้อมูลและผูกบัญชีครบทั้งหมดเรียบร้อยแล้ว!${C_RESET}"
        sleep 2
    else
        echo -e "${C_RED}❌ ไม่พบแพ็กเกจที่คุณค้นหาในเครื่องนี้${C_RESET}"
        rm "temp_pkg.txt" 2>/dev/null
        sleep 2
    fi
}

# ==========================================
# ระบบวาดตาราง Live Dashboard
# ==========================================
draw_dashboard() {
    stty onlcr sane 2>/dev/null 
    clear
    show_header
    echo -e "${C_CYAN}--- 📊 Smart Rejoin Dashboard ---${C_RESET}"
    echo -e "▶️ สถานะระบบ: ${global_msg}"
    echo "================================================================="
    printf "| %-16s | %-16s | %-20s |\n" "📱 Package" "👤 Account" "📌 Status"
    echo "================================================================="
    for j in "${!pkgs[@]}"; do
        local pkg="${pkgs[$j]}"
        local acc="${unames[$j]}"
        local stat="${statuses[$j]}"
        local col="${colors[$j]}"
        printf "| %-16s | %-16s | ${col}%-20s${C_RESET} \vert{}\n" "$pkg" "$acc" "$stat"
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
    if [ -d "$cache_path" ]; then safe_su "rm -rf $cache_path/*"; fi

    statuses[$idx]="กำลังปิด (Kill)"
    colors[$idx]="$C_RED"
    draw_dashboard
    
    safe_su "am force-stop $p"
    safe_su "am force-stop --user all $p"
    sleep 2

    statuses[$idx]="เปิดหน้าแรก"
    colors[$idx]="$C_GREEN"
    
    safe_su "monkey -p \"$p\" -c android.intent.category.LAUNCHER 1"
    
    for (( w=5; w>0; w-- )); do
        statuses[$idx]="รอเข้าเกม ${w}s..."
        draw_dashboard
        sleep 1
    done
    
    statuses[$idx]="ส่งเข้าแมพ (Map)"
    draw_dashboard
    
    safe_su "am start -f 0x10000000 -a android.intent.action.VIEW -d \"roblox://placeId=$place_id\" -p \"$p\""
    
    launch_times[$idx]=$(date +%s)
    if [ -n "${ping_paths[$idx]}" ] && [ -f "${ping_paths[$idx]}" ]; then
        safe_su "rm \"${ping_paths[$idx]}\""
    fi
    ping_paths[$idx]=""
    
    statuses[$idx]="กำลังโหลด (Loading)"
    colors[$idx]="$C_YELLOW"
}

# ==========================================
# เมนู 1: ระบบ Rejoin Loop
# ==========================================
start_auto_rejoin() {
    clear
    show_header
    if [ ! -f "$CONFIG_FILE" ] \vert{}\vert{} [ ! -s "$CONFIG_FILE" ]; then
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
        global_msg="${C_CYAN}👀 ระบบ Rejoin กำลังตรวจสอบการตอบสนอง...${C_RESET}"
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
                
                if [[ "$last_ping" == "DEAD" ]]; then
                    statuses[$i]="หลุด! (Error Msg)"
                    colors[$i]="$C_RED"
                    draw_dashboard
                    relaunch_pkg "$pkg" "$i"
                elif [[ "$last_ping" =~ ^[0-9]+$ ]]; then
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
# ดักจับ Ctrl+C เพื่อคืนค่า Cursor และซ่อมหน้าจอ
# ==========================================
trap 'tput cnorm; clear; stty onlcr sane 2>/dev/null; exit' INT

# ==========================================
# เริ่มต้นการทำงาน 
# ==========================================
check_root

# ==========================================
# เมนูหลัก (Main Menu)
# ==========================================
while true; do
    clear
    show_header
    echo -e "${C_CYAN}Available Features:${C_RESET}"
    echo -e "${C_CYAN}1.${C_RESET} Start Auto Rejoin (Smart System)"
    echo -e "${C_CYAN}2.${C_RESET} Start Auto Setup (Detect Packages & Bind Accounts)"
    echo -e "${C_CYAN}3.${C_RESET} Add Discord Webhook & Heartbeat to Autoexec"
    echo -e "${C_CYAN}0.${C_RESET} Exit"
    echo ""
    read -p "Select an option: " opt_main
    case $opt_main in
        1) start_auto_rejoin ;;
        2) start_auto_setup ;;
        3) setup_webhook ;;
        0) clear; tput cnorm; stty onlcr sane 2>/dev/null; exit 0 ;;
        *) echo -e "${C_RED}Invalid option!${C_RESET}"; sleep 1 ;;
    esac
done

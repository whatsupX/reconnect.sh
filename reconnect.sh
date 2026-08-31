#!/bin/bash

# กำหนดค่าสี
C_CYAN='\e[36m'
C_GREEN='\e[32m'
C_YELLOW='\e[33m'
C_RED='\e[31m'
C_PURPLE='\e[35m'
C_RESET='\e[0m'
CONFIG_FILE="roblox_accounts.cfg"

show_header() {
    clear
    echo -e "${C_CYAN}"
    echo " _ __ ___  ___ ___  _ __  _ __   ___  ___| |_"
    echo "| '__/ _ \/ __/ _ \| '_ \| '_ \ / _ \/ __| __|"
    echo "| | |  __/ (_| (_) | | | | | | |  __/ (__| |_"
    echo "|_|  \___|\___\___/|_| |_|_| |_|\___|\___|\__|"
    echo "              Made for Multi-Account v2.0"
    echo -e "${C_RESET}"
}

# ==========================================
# เมนู 2: ระบบตั้งค่าอัตโนมัติ (Auto Setup)
# ==========================================
start_auto_setup() {
    show_header
    echo -e "${C_CYAN}--- Automatic Setup (Detect Packages) ---${C_RESET}"
    echo ""
    echo -e "${C_YELLOW}🔄 ระบบกำลังค้นหาแพ็กเกจโคลนทั้งหมด...${C_RESET}"
    sleep 1

    pm list packages | grep "roblox.clien" | cut -f 2 -d ':' > "$CONFIG_FILE"
    screen_count=$(wc -l < "$CONFIG_FILE")

    if [ "$screen_count" -gt 0 ]; then
        echo -e "${C_GREEN}✅ ตรวจพบและบันทึกอัตโนมัติจำนวน $screen_count จอ ดังนี้:${C_RESET}"
        cat "$CONFIG_FILE" | while read -r pkg; do
            echo -e "   - $pkg"
        done
        echo ""
        echo -e "${C_GREEN}🎉 บันทึกข้อมูลสำเร็จ! คุณสามารถไปที่เมนู Auto Rejoin ได้เลย${C_RESET}"
    else
        echo -e "${C_RED}❌ ไม่พบแพ็กเกจโคลนที่ขึ้นต้นด้วย 'roblox.clien' ในเครื่อง!${C_RESET}"
    fi
    
    sleep 4
}

# ==========================================
# เมนู 1: ระบบ Rejoin พร้อมเช็คสถานะและ Toast
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
        
        while IFS= read -r pkg || [ -n "$pkg" ]; do
            echo -e "${C_YELLOW}🛑 Killing process: $pkg...${C_RESET}"
            am force-stop "$pkg" > /dev/null 2>&1
            sleep 2
            
            max_retries=3
            attempt=1
            success=0

            while [ $attempt -le $max_retries ]; do
                echo -e "${C_GREEN}🚀 Launching: $pkg (รอบที่ $attempt)...${C_RESET}"
                am start -a android.intent.action.VIEW -d "roblox://placeId=$place_id" -p "$pkg" > /dev/null 2>&1
                
                sleep 4 
                
                if pidof "$pkg" > /dev/null; then
                    echo -e "${C_CYAN}✅ เปิดสำเร็จ!${C_RESET}"
                    success=1
                    break
                else
                    echo -e "${C_RED}⚠️ เปิดไม่สำเร็จ กำลังลองใหม่...${C_RESET}"
                    attempt=$((attempt + 1))
                fi
            done

            if [ $success -eq 0 ]; then
                echo -e "${C_RED}❌ ข้ามจอ $pkg เนื่องจากเปิดไม่สำเร็จ $max_retries ครั้ง${C_RESET}"
                
                # แสดงแจ้งเตือน Toast ป๊อปอัพบนหน้าจอมือถือ
                if command -v termux-toast > /dev/null 2>&1; then
                    termux-toast -b red -c white "แจ้งเตือน: เปิดจอ $pkg ไม่สำเร็จ!"
                fi
            fi

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
    echo -e "${C_CYAN}1.${C_RESET} Start Auto Rejoin (Multi-Account)"
    echo -e "${C_CYAN}2.${C_RESET} Start Auto Setup (Detect Packages)"
    echo -e "${C_CYAN}3.${C_RESET} View Saved Packages"
    echo -e "${C_CYAN}0.${C_RESET} Exit"
    echo ""
    read -p "Select an option: " opt_main

    case $opt_main in
        1) start_auto_rejoin ;;
        2) start_auto_setup ;;
        3) 
            show_header
            echo -e "${C_CYAN}--- Saved Packages ---${C_RESET}"
            if [ -f "$CONFIG_FILE" ]; then
                cat "$CONFIG_FILE"
            else
                echo -e "${C_RED}No packages saved yet.${C_RESET}"
            fi
            echo ""
            read -p "Press Enter to return..."
            ;;
        0) clear; exit 0 ;;
        *) echo -e "${C_RED}Invalid option!${C_RESET}"; sleep 1 ;;
    esac
done

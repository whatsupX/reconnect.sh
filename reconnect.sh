#!/bin/bash

# ==========================================
# กำหนดค่าสี
# ==========================================
C_CYAN='\033[36m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_RED='\033[31m'
C_PURPLE='\033[35m'
C_RESET='\033[0m'

CONFIG_FILE="roblox_accounts.cfg"
WEBHOOK_FILE="webhook.cfg"
COOKIE_FILE="roblox_cookies.cfg"
LUA_FILENAME="status_check.lua"
TEMP_LUA="/storage/emulated/0/temp_status_check.lua"
TEMP_FOLDERS="/storage/emulated/0/temp_autoexec_folders.txt"
DL_COOKIE_FILE="/storage/emulated/0/Download/cookie.txt"

# ค่าเบราว์เซอร์ปลอมเพื่อหลบหลีกการบล็อกของ Roblox
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# ล้างไฟล์ตั้งค่าที่พัง
if [[ -f "$CONFIG_FILE" ]]; then
    check_bad=$(grep "vert" "$CONFIG_FILE" 2>/dev/null)
    if [[ -n "$check_bad" ]]; then
        rm "$CONFIG_FILE"
    fi
fi

# ==========================================
# ฟังก์ชันแสดงส่วนหัว
# ==========================================
show_header() {
    echo -e "${C_CYAN}██╗    ██╗██╗  ██╗ █████╗ ████████╗███████╗██╗   ██╗██████╗ ██╗  ██╗${C_RESET}"
    echo -e "${C_CYAN}██║    ██║██║  ██║██╔══██╗╚══██╔══╝██╔════╝██║   ██║██╔══██╗╚██╗██╔╝${C_RESET}"
    echo -e "${C_CYAN}██║ █╗ ██║███████║███████║   ██║   ███████╗██║   ██║██████╔╝ ╚███╔╝ ${C_RESET}"
    echo -e "${C_CYAN}██║███╗██║██╔══██║██╔══██║   ██║   ╚════██║██║   ██║██╔═══╝  ██╔██╗ ${C_RESET}"
    echo -e "${C_CYAN}╚███╔███╔╝██║  ██║██║  ██║   ██║   ███████║╚██████╔╝██║     ██╔╝ ██╗${C_RESET}"
    echo -e "${C_CYAN} ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝${C_RESET}"
    echo -e "${C_YELLOW}      v10.6 (Deep Path Fix) :: Made by whatsupX${C_RESET}"
    echo ""
}

# ==========================================
# ฟังก์ชันรันคำสั่ง Root
# ==========================================
safe_su() {
    su -c "$1" < /dev/null > /dev/null 2>&1
    stty onlcr sane 2>/dev/null
    printf "\r"
}

# ==========================================
# ระบบตรวจสอบ Root
# ==========================================
check_root() {
    stty onlcr sane 2>/dev/null
    clear
    show_header
    echo -e "${C_CYAN}🔍 กำลังตรวจสอบสิทธิ์ Root ในเครื่อง...${C_RESET}"
    
    if ! su -c 'true' < /dev/null > /dev/null 2>&1; then
        echo -e "${C_RED}❌ ตรวจพบว่าเครื่องของคุณยังไม่ได้ Root!${C_RESET}"
        exit 1
    else
        echo -e "${C_GREEN}✅ ตรวจพบสิทธิ์ Root เรียบร้อยแล้ว!${C_RESET}"
        sleep 1
    fi
    stty onlcr sane 2>/dev/null
}

# ==========================================
# ฝัง Lua อัตโนมัติ (เพิ่มความลึกในการค้นหาเป็น 10)
# ==========================================
inject_lua_script() {
    echo -e "${C_YELLOW}🔍 กำลังตรวจสอบและฝังสคริปต์ลงใน Autoexec อัตโนมัติ...${C_RESET}"
    
    local saved_webhook=""
    if [[ -f "$WEBHOOK_FILE" ]]; then
        saved_webhook=$(tr -d '\r\n' < "$WEBHOOK_FILE")
    fi

    # 📌 แก้บั๊ก: เพิ่ม maxdepth เป็น 10 เพื่อให้มุดหาใน /Android/data/... ลึกๆ ได้
    su -c "find /storage/emulated/0 -maxdepth 10 -type d -iname 'autoexec' 2>/dev/null > '$TEMP_FOLDERS'"

    if [[ ! -s "$TEMP_FOLDERS" ]]; then
        echo -e "${C_YELLOW}⚠️ ไม่พบโฟลเดอร์ Autoexec (ระบบอาจสร้างขึ้นหลังจากเปิดเกมรอบแรก)${C_RESET}"
        sleep 2
        return
    fi

    cat <<EOF > "$TEMP_LUA"
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local webhookUrl = "$saved_webhook"
local playerName = player and player.Name or "Unknown"
local displayName = player and player.DisplayName or "Unknown"
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request
local isDisconnected = false

local function sendWebhook(title, desc, colorHex)
    if webhookUrl == "" or not httpRequest then return end
    local data = {
        ["embeds"] = {{
            ["title"] = title, ["description"] = desc, ["color"] = colorHex,
            ["fields"] = {
                {["name"] = "Username", ["value"] = playerName, ["inline"] = true},
                {["name"] = "Display Name", ["value"] = displayName, ["inline"] = true}
            },
            ["footer"] = {["text"] = "TH REJOIN TOOL"}
        }}
    }
    pcall(function() httpRequest({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data)}) end)
end

sendWebhook("✅ เข้าร่วมเซิร์ฟเวอร์สำเร็จ!", "**JobId:** \`" .. tostring(game.JobId) .. "\`", 65280)

GuiService.ErrorMessageChanged:Connect(function(errorMsg)
    if errorMsg and errorMsg ~= "" then 
        isDisconnected = true
        pcall(function() writefile("ping_" .. playerName .. ".txt", "DEAD") end)
        sendWebhook("❌ หลุดออกจากเกม!", "**สาเหตุ:** " .. errorMsg, 16711680) 
    end
end)

task.spawn(function()
    while task.wait(10) do
        if isDisconnected then break end
        pcall(function() writefile("ping_" .. playerName .. ".txt", tostring(os.time())) end)
    end
end)
EOF

    while read -r folder; do
        if [[ -n "$folder" ]]; then
            local target_path="$folder/$LUA_FILENAME"
            su -c "cp '$TEMP_LUA' '$target_path' 2>/dev/null"
            su -c "chmod 777 '$target_path' 2>/dev/null"
            echo -e "${C_GREEN}✔️ ฝังสคริปต์อัปเดตลงใน: $folder${C_RESET}"
        fi
    done < "$TEMP_FOLDERS"

    rm "$TEMP_LUA" 2>/dev/null
    rm "$TEMP_FOLDERS" 2>/dev/null
    sleep 2
}

# ==========================================
# เมนู 5: รันล็อคอินเข้าหน้าแรก (ไม่เข้าแมพ)
# ==========================================
execute_cookie_login() {
    clear
    show_header
    echo -e "${C_CYAN}--- Execute Cookie Login (Home Screen) ---${C_RESET}"
    
    if [[ ! -s "$COOKIE_FILE" ]]; then
        echo -e "${C_RED}❌ ไม่พบข้อมูล Cookie! กรุณาไปทำเมนู 4 หรือเมนู 2 เพื่อตั้งค่าก่อน${C_RESET}"
        sleep 3
        return
    fi

    echo -e "${C_YELLOW}🚀 กำลังเริ่มกระบวนการล็อคอินเข้าหน้าแรกทีละจอ...${C_RESET}"
    
    while read -r line; do
        if [[ -z "$line" ]]; then continue; fi
        
        local pkg=$(echo "$line" | cut -d' ' -f1)
        local active_cookie=$(echo "$line" | cut -d' ' -f2-)
        
        if [[ -n "$pkg" && -n "$active_cookie" ]]; then
            echo -e "\n${C_CYAN}📱 กำลังดำเนินการจอ: ${pkg}${C_RESET}"
            
            safe_su "am force-stop $pkg"
            sleep 2
            
            echo -e "${C_YELLOW}🔄 กำลังขอ Ticket จากเซิร์ฟเวอร์ Roblox...${C_RESET}"
            local csrf=$(curl -s -k -L -I -X POST "https://auth.roblox.com/v2/logout" \
                -H "Cookie: .ROBLOSECURITY=$active_cookie" \
                -H "User-Agent: $UA" \
                | grep -i 'x-csrf-token:' | awk '{print $2}' | tr -d '\r\n')
            
            if [[ -n "$csrf" ]]; then
                local ticket=$(curl -s -k -L -I -X POST "https://auth.roblox.com/v1/authentication-ticket" \
                    -H "Cookie: .ROBLOSECURITY=$active_cookie" \
                    -H "x-csrf-token: $csrf" \
                    -H "Referer: https://www.roblox.com" \
                    -H "Content-Type: application/json" \
                    -H "User-Agent: $UA" \
                    | grep -i 'rbx-authentication-ticket:' | awk '{print $2}' | tr -d '\r\n')
                
                if [[ -n "$ticket" ]]; then
                    echo -e "${C_GREEN}✅ ได้รับ Ticket สำเร็จ! กำลังส่งเข้าหน้าแรก...${C_RESET}"
                    safe_su "am start -a android.intent.action.VIEW -d 'roblox://?ticket=$ticket' -p '$pkg'"
                else
                    echo -e "${C_RED}❌ ขอ Ticket ไม่สำเร็จ (Cookie อาจหมดอายุหรือติด IP Lock)${C_RESET}"
                fi
            else
                echo -e "${C_RED}❌ ขอ CSRF Token ไม่สำเร็จ (Cookie ไม่ถูกต้อง)${C_RESET}"
            fi
            
            echo -e "${C_YELLOW}⏳ รอ 5 วินาทีเพื่อดำเนินการจอถัดไป...${C_RESET}"
            sleep 5
        fi
    done < "$COOKIE_FILE"
    
    echo -e "\n${C_GREEN}🎉 กระบวนการล็อคอินเสร็จสิ้นทั้งหมดแล้ว!${C_RESET}"
    read -p "กด Enter เพื่อกลับไปเมนูหลัก..."
}

# ==========================================
# เมนู 4: ระบบใส่ Cookie (จากไฟล์)
# ==========================================
setup_cookie() {
    clear
    show_header
    echo -e "${C_CYAN}--- Setup Cookie & Auto Bind Accounts ---${C_RESET}"
    
    > "temp_pkg.txt"
    screen_count=0
    for line in $(pm list packages); do
        if [[ "${line,,}" == *roblox.clien* ]]; then
            pkg_name="${line#package:}"
            echo "$pkg_name" >> "temp_pkg.txt"
            ((screen_count++))
        fi
    done
    stty onlcr sane 2>/dev/null

    if (( screen_count == 0 )); then
        echo -e "${C_RED}❌ ไม่พบแพ็กเกจที่ชื่อ 'roblox.clien'${C_RESET}"
        read -p "🔍 พิมพ์ชื่อแอป (เช่น roblox, arceus) เพื่อหาใหม่: " custom_pkg
        
        if [[ -n "$custom_pkg" ]]; then
            echo -e "${C_YELLOW}🔄 กำลังค้นหาคำว่า '$custom_pkg'...${C_RESET}"
            > "temp_pkg.txt"
            for line in $(pm list packages); do
                if [[ "${line,,}" == *"${custom_pkg,,}"* ]]; then
                    pkg_name="${line#package:}"
                    echo "$pkg_name" >> "temp_pkg.txt"
                    ((screen_count++))
                fi
            done
            stty onlcr sane 2>/dev/null
        fi
    fi

    if (( screen_count == 0 )); then
        echo -e "${C_RED}❌ ไม่พบแพ็กเกจเลย ยกเลิกการทำรายการ${C_RESET}"
        rm "temp_pkg.txt" 2>/dev/null
        sleep 2
        return
    fi

    echo -e "${C_GREEN}✅ ตรวจพบ $screen_count จอในเครื่องนี้!${C_RESET}"

    if [[ ! -f "$DL_COOKIE_FILE" ]]; then
        echo -e "${C_YELLOW}⚠️ ไม่พบไฟล์ cookie.txt${C_RESET}"
        echo -e "${C_GREEN}สร้างไฟล์ให้ใหม่แล้วที่: Download/cookie.txt${C_RESET}"
        echo "# วาง Cookie ของคุณไว้ที่นี่ (1 บรรทัดต่อ 1 จอ)" > "$DL_COOKIE_FILE"
    else
        echo -e "${C_CYAN}📂 พบไฟล์ cookie.txt ในโฟลเดอร์ Download แล้ว${C_RESET}"
    fi

    echo -e "\n${C_YELLOW}💡 กรุณาเปิดแอปจัดการไฟล์ ไปที่โฟลเดอร์ Download${C_RESET}"
    echo -e "${C_YELLOW}💡 เปิดไฟล์ cookie.txt แล้ววาง Cookie ลงไปให้เรียบร้อย${C_RESET}"
    echo -e "${C_RED}⚠️ เมื่อใส่เสร็จแล้ว ให้กลับมาที่นี่แล้วกด Enter เพื่อยืนยัน${C_RESET}\n"

    read -p "กด Enter เพื่อให้ระบบเริ่มดึงข้อมูลจากไฟล์..."

    local found_pkgs=()
    while read -r line; do 
        if [[ -n "$line" ]]; then found_pkgs+=("$line"); fi
    done < "temp_pkg.txt"
    
    local found_cookies=()
    if [[ -f "$DL_COOKIE_FILE" ]]; then
        while read -r line; do 
            if [[ "$line" == \#* ]]; then continue; fi
            line=$(echo "$line" | sed 's/^\xef\xbb\xbf//' | tr -d '\r\n\t ')
            if [[ -n "$line" ]]; then found_cookies+=("$line"); fi
        done < "$DL_COOKIE_FILE"
    fi

    local cookie_count=${#found_cookies[@]}
    
    if (( cookie_count == 0 )); then
        echo -e "\n${C_RED}❌ ไม่พบ Cookie ในไฟล์ หรือไฟล์ว่างเปล่า!${C_RESET}"
        rm "temp_pkg.txt" 2>/dev/null
        sleep 3
        return
    fi

    echo -e "\n${C_CYAN}📌 อ่าน Cookie จากไฟล์ได้ทั้งหมด: $cookie_count ไอดี${C_RESET}"
    echo -e "${C_YELLOW}⏳ กำลังตรวจสอบ Cookie และดึง Username อัตโนมัติจาก Roblox...${C_RESET}\n"
    
    > "$COOKIE_FILE"
    > "$CONFIG_FILE" 
    local assigned=0
    
    for i in "${!found_pkgs[@]}"; do
        local pkg="${found_pkgs[$i]}"
        pkg="${pkg//[$'\t\r\n ']/}"
        
        if (( i < cookie_count )); then
            local cookie_val="${found_cookies[$i]}"
            
            local api_res=$(curl -s -k -L -X GET "https://users.roblox.com/v1/users/authenticated" \
                -H "Cookie: .ROBLOSECURITY=$cookie_val" \
                -H "User-Agent: $UA")
                
            local uname=$(echo "$api_res" | grep -o '"name":"[^"]*' | head -n 1 | awk -F'"' '{print $4}')
            
            if [[ -z "$uname" ]]; then
                echo -e "${C_RED}❌ จอ $pkg: Cookie หมดอายุ หรือติด IP Lock! (ตั้งเป็น Unknown)${C_RESET}"
                uname="Unknown"
            else
                echo -e "${C_GREEN}✔️ จอ $pkg ผูกกับ Username: 👤 $uname${C_RESET}"
            fi
            
            echo "$pkg $cookie_val" >> "$COOKIE_FILE"
            echo "$pkg:$uname" >> "$CONFIG_FILE"
            ((assigned++))
        fi
    done
    
    rm "temp_pkg.txt" 2>/dev/null
    
    echo -e "\n${C_GREEN}🎉 บันทึก Cookie และผูกบัญชีสำเร็จ! (ดำเนินการให้ $assigned จอ)${C_RESET}"
    sleep 4
}

# ==========================================
# เมนู 3: จัดการ Webhook
# ==========================================
setup_webhook() {
    clear
    show_header
    echo -e "${C_CYAN}--- Manage Discord Webhook ---${C_RESET}"
    
    if [[ -f "$WEBHOOK_FILE" ]]; then
        local current_hook=$(tr -d '\r\n' < "$WEBHOOK_FILE")
        echo -e "${C_YELLOW}📌 Webhook ปัจจุบัน: ${current_hook}${C_RESET}"
    else
        echo -e "${C_YELLOW}📌 Webhook ปัจจุบัน: (ยังไม่ได้ตั้งค่า)${C_RESET}"
    fi

    echo -e "${C_YELLOW}< กด Enter โดยไม่พิมพ์อะไร เพื่อใช้ข้อมูลเดิม หรือยกเลิก >${C_RESET}"
    echo -e "${C_YELLOW}< พิมพ์คำว่า 'clear' เพื่อลบ Webhook ทิ้ง >${C_RESET}"
    read -p "🔗 กรุณาใส่ลิงก์ Discord Webhook ใหม่: " webhook_url
    
    if [[ "$webhook_url" == "clear" ]]; then
        rm "$WEBHOOK_FILE" 2>/dev/null
        echo -e "${C_GREEN}✅ ลบ Webhook เรียบร้อยแล้ว!${C_RESET}"
    elif [[ -n "$webhook_url" ]]; then
        echo "$webhook_url" > "$WEBHOOK_FILE"
        echo -e "${C_GREEN}✅ บันทึก Webhook เรียบร้อยแล้ว!${C_RESET}"
    fi

    inject_lua_script
    
    echo ""
    read -p "กด Enter เพื่อกลับไปเมนูหลัก..."
}

# ==========================================
# เมนู 2.1: Manual Bind (พิมพ์ชื่อเอง)
# ==========================================
setup_manual_bind() {
    clear
    show_header
    echo -e "${C_CYAN}--- Auto Setup (Manual Bind) ---${C_RESET}"
    
    > "temp_pkg.txt"
    screen_count=0
    for line in $(pm list packages); do
        if [[ "${line,,}" == *roblox.clien* ]]; then
            pkg_name="${line#package:}"
            echo "$pkg_name" >> "temp_pkg.txt"
            ((screen_count++))
        fi
    done
    stty onlcr sane 2>/dev/null

    if (( screen_count == 0 )); then
        read -p "🔍 ไม่พบ 'roblox.clien' พิมพ์ชื่อแอป (เช่น arceus) เพื่อหาใหม่: " custom_pkg
        if [[ -n "$custom_pkg" ]]; then
            > "temp_pkg.txt"
            for line in $(pm list packages); do
                if [[ "${line,,}" == *"${custom_pkg,,}"* ]]; then
                    pkg_name="${line#package:}"
                    echo "$pkg_name" >> "temp_pkg.txt"
                    ((screen_count++))
                fi
            done
            stty onlcr sane 2>/dev/null
        fi
    fi

    if (( screen_count > 0 )); then
        echo -e "${C_GREEN}✅ ตรวจพบ $screen_count จอ!${C_RESET}"
        echo ""
        
        local found_pkgs=()
        while read -r line; do 
            if [[ -n "$line" ]]; then found_pkgs+=("$line"); fi
        done < "temp_pkg.txt"
        
        local input_data=()
        for pkg in "${found_pkgs[@]}"; do
            pkg="${pkg//[$'\t\r\n ']/}"
            stty onlcr sane 2>/dev/null
            read -p "👤 ใส่ Username ของจอ <$pkg>: " uname
            if [[ -z "$uname" ]]; then uname="Unknown"; fi
            input_data+=("$pkg:$uname")
        done
        
        > "$CONFIG_FILE"
        for data in "${input_data[@]}"; do
            echo "$data" >> "$CONFIG_FILE"
        done
        
        rm "temp_pkg.txt" 2>/dev/null
        echo -e "\n${C_GREEN}🎉 บันทึกข้อมูลเรียบร้อยแล้ว!${C_RESET}"
        sleep 2
    else
        echo -e "${C_RED}❌ ไม่พบแพ็กเกจเลย${C_RESET}"
        rm "temp_pkg.txt" 2>/dev/null
        sleep 2
    fi
}

# ==========================================
# เมนู 2.2: Deep Scan Auto Bind (สแกนอัตโนมัติ)
# ==========================================
setup_deep_scan() {
    clear
    show_header
    echo -e "${C_CYAN}--- Auto Setup (Deep Scan Mode) ---${C_RESET}"
    
    > "temp_pkg.txt"
    screen_count=0
    for line in $(pm list packages); do
        if [[ "${line,,}" == *roblox.clien* ]]; then
            pkg_name="${line#package:}"
            echo "$pkg_name" >> "temp_pkg.txt"
            ((screen_count++))
        fi
    done
    stty onlcr sane 2>/dev/null

    if (( screen_count == 0 )); then
        read -p "🔍 ไม่พบ 'roblox.clien' พิมพ์ชื่อแอป (เช่น arceus) เพื่อหาใหม่: " custom_pkg
        if [[ -n "$custom_pkg" ]]; then
            > "temp_pkg.txt"
            for line in $(pm list packages); do
                if [[ "${line,,}" == *"${custom_pkg,,}"* ]]; then
                    pkg_name="${line#package:}"
                    echo "$pkg_name" >> "temp_pkg.txt"
                    ((screen_count++))
                fi
            done
            stty onlcr sane 2>/dev/null
        fi
    fi

    if (( screen_count > 0 )); then
        echo -e "${C_GREEN}✅ ตรวจพบ $screen_count จอ!${C_RESET}"
        echo -e "${C_YELLOW}🚀 กำลังมุดเข้าข้อมูลแอปเพื่อสแกนหา Username (โปรดรอสักครู่)...${C_RESET}\n"
        
        local found_pkgs=()
        while read -r line; do 
            if [[ -n "$line" ]]; then found_pkgs+=("$line"); fi
        done < "temp_pkg.txt"
        
        > "$CONFIG_FILE"
        local new_cookies=0
        
        for pkg in "${found_pkgs[@]}"; do
            pkg="${pkg//[$'\t\r\n ']/}"
            echo -e "${C_CYAN}🔍 ตรวจสอบจอ: ${pkg}...${C_RESET}"
            local uname=""
            
            local extracted_cookie=$(su -c "grep -a -r -m 1 -h -o '_\vert{}WARNING:-DO-NOT-SHARE-THIS[^<\"]*' /data/data/$pkg/ 2>/dev/null" | tr -d '\r\n')
            
            if [[ -n "$extracted_cookie" ]]; then
                local api_res=$(curl -s -k -L -X GET "https://users.roblox.com/v1/users/authenticated" -H "Cookie: .ROBLOSECURITY=$extracted_cookie" -H "User-Agent: $UA")
                uname=$(echo "$api_res" | grep -o '"name":"[^"]*' | head -n 1 | awk -F'"' '{print $4}')
                
                if [[ -n "$uname" ]]; then
                    echo -e "${C_GREEN}   ✔️ เจอคุกกี้! ดึงชื่อสำเร็จ: 👤 $uname${C_RESET}"
                    
                    if ! grep -q "^$pkg " "$COOKIE_FILE" 2>/dev/null; then
                        echo "$pkg $extracted_cookie" >> "$COOKIE_FILE"
                        echo -e "${C_PURPLE}   ✔️ นำคุกกี้บันทึกลงระบบ Auto-Login ให้อัตโนมัติ!${C_RESET}"
                        ((new_cookies++))
                    fi
                fi
            fi

            if [[ -z "$uname" ]]; then
                local ping_file=$(su -c "find /storage/emulated/0/Android/data/$pkg -type f -name 'ping_*.txt' 2>/dev/null | head -n 1")
                if [[ -n "$ping_file" ]]; then
                    local filename="${ping_file##*/}" 
                    uname="${filename#ping_}"         
                    uname="${uname%.txt}"             
                    if [[ -n "$uname" ]]; then
                        echo -e "${C_GREEN}   ✔️ ดึงชื่อจากไฟล์ชีพจรสำเร็จ: 👤 $uname${C_RESET}"
                    fi
                fi
            fi

            if [[ -z "$uname" ]]; then
                echo -e "${C_RED}   ⚠️ สแกนไม่พบข้อมูล (แอปอาจจะใหม่เกินไป หรือเข้ารหัสไว้)${C_RESET}"
                stty onlcr sane 2>/dev/null
                tput cnorm
                read -p "   👤 โปรดพิมพ์ Username เอง (ปล่อยว่าง=Unknown): " uname
                if [[ -z "$uname" ]]; then uname="Unknown"; fi
            fi
            
            echo "$pkg:$uname" >> "$CONFIG_FILE"
            echo ""
        done
        
        rm "temp_pkg.txt" 2>/dev/null
        echo -e "${C_GREEN}🎉 บันทึกข้อมูลและผูกหน้าจอเรียบร้อยแล้ว!${C_RESET}"
        sleep 4
    else
        echo -e "${C_RED}❌ ไม่พบแพ็กเกจเลย${C_RESET}"
        rm "temp_pkg.txt" 2>/dev/null
        sleep 2
    fi
}

# ==========================================
# เมนู 2: เลือกโหมด Auto Setup (แยกเมนูย่อย)
# ==========================================
start_auto_setup_menu() {
    while true; do
        clear
        show_header
        echo -e "${C_CYAN}┌────────────────────────────────────────────────────────┐${C_RESET}"
        echo -e "${C_CYAN}│${C_RESET}               ${C_YELLOW}--- Auto Setup Options ---${C_RESET}               ${C_CYAN}│${C_RESET}"
        echo -e "${C_CYAN}├────────────────────────────────────────────────────────┤${C_RESET}"
        echo -e "${C_CYAN}│${C_RESET}  ${C_GREEN}1${C_RESET}  Manual Setup        ${C_YELLOW}พิมพ์ชื่อบัญชีผูกกับจอเอง${C_RESET}      ${C_CYAN}│${C_RESET}"
        echo -e "${C_CYAN}│${C_RESET}  ${C_GREEN}2${C_RESET}  Deep Scan (Beta)    ${C_YELLOW}สแกนหาชื่อในแอปอัตโนมัติ${C_RESET}       ${C_CYAN}│${C_RESET}"
        echo -e "${C_CYAN}│${C_RESET}                                                        ${C_CYAN}│${C_RESET}"
        echo -e "${C_CYAN}│${C_RESET}  ${C_GREEN}0${C_RESET}  Back                ${C_YELLOW}กลับสู่เมนูหลัก${C_RESET}                 ${C_CYAN}│${C_RESET}"
        echo -e "${C_CYAN}└────────────────────────────────────────────────────────┘${C_RESET}"
        echo ""
        read -p "select: " opt_setup
        case $opt_setup in
            1) setup_manual_bind; break ;;
            2) setup_deep_scan; break ;;
            0) break ;;
            *) echo -e "${C_RED}Invalid option!${C_RESET}"; sleep 1 ;;
        esac
    done
}

# ==========================================
# ระบบวาดตาราง Dashboard 
# ==========================================
draw_dashboard() {
    stty onlcr sane 2>/dev/null 
    clear
    show_header
    echo -e "${C_CYAN}--- 📊 Smart Rejoin Dashboard ---${C_RESET}"
    echo -e "▶️ สถานะระบบ: ${global_msg}"
    
    echo -e "${C_CYAN}┌──────────────────┬──────────────────┬──────────────────────┐${C_RESET}"
    printf "${C_CYAN}│${C_RESET} %-16s ${C_CYAN}│${C_RESET} %-16s ${C_CYAN}│${C_RESET} %-20s ${C_CYAN}│${C_RESET}\n" "Package" "Account" "Status"
    echo -e "${C_CYAN}├──────────────────┼──────────────────┼──────────────────────┤${C_RESET}"
    
    for j in "${!pkgs[@]}"; do
        local pkg="${pkgs[$j]}"
        local acc="${unames[$j]}"
        local stat="${statuses[$j]}"
        local col="${colors[$j]}"
        printf "${C_CYAN}│${C_RESET} \%-16s${C_CYAN}│${C_RESET} \%-16s${C_CYAN}│${C_RESET}${col}%-20s${C_RESET}${C_CYAN}│${C_RESET}\n" "$pkg" "$acc" "$stat"
    done
    
    echo -e "${C_CYAN}└──────────────────┴──────────────────┴──────────────────────┘${C_RESET}"
    echo -e "${C_RED}< กด Ctrl+C เพื่อหยุดการทำงาน >${C_RESET}"
}

# ==========================================
# ฟังก์ชันเปิดจอเข้าแมพ (ดึงเข้าเกม)
# ==========================================
relaunch_pkg() {
    local p="$1"
    local idx="$2"
    
    statuses[$idx]="ล้างแคช..."
    colors[$idx]="$C_CYAN"
    draw_dashboard
    cache_path="/storage/emulated/0/Android/data/$p/cache"
    if [[ -d "$cache_path" ]]; then safe_su "rm -rf $cache_path/*"; fi

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

    local active_cookie=""
    if [[ -f "$COOKIE_FILE" ]]; then
        active_cookie=$(grep "^$p " "$COOKIE_FILE" 2>/dev/null | cut -d' ' -f2-)
    fi

    local ticket=""
    if [[ -n "$active_cookie" ]]; then
        statuses[$idx]="ยืนยัน Cookie..."
        colors[$idx]="$C_CYAN"
        draw_dashboard
        
        local csrf=$(curl -s -k -L -I -X POST "https://auth.roblox.com/v2/logout" \
            -H "Cookie: .ROBLOSECURITY=$active_cookie" \
            -H "User-Agent: $UA" \
            | grep -i 'x-csrf-token:' | awk '{print $2}' | tr -d '\r\n')
        
        if [[ -n "$csrf" ]]; then
            ticket=$(curl -s -k -L -I -X POST "https://auth.roblox.com/v1/authentication-ticket" \
                -H "Cookie: .ROBLOSECURITY=$active_cookie" \
                -H "x-csrf-token: $csrf" \
                -H "Referer: https://www.roblox.com" \
                -H "Content-Type: application/json" \
                -H "User-Agent: $UA" \
                | grep -i 'rbx-authentication-ticket:' | awk '{print $2}' | tr -d '\r\n')
        fi
    fi
    
    statuses[$idx]="ส่งเข้าแมพ (Map)"
    colors[$idx]="$C_GREEN"
    draw_dashboard
    
    local launch_url=""
    
    if [[ "$mode_choice" == "1" ]]; then
        launch_url="roblox://placeId=${place_id}"
        if [[ -n "$ticket" ]]; then
            launch_url="${launch_url}&ticket=${ticket}"
        fi
    elif [[ "$mode_choice" == "2" ]]; then
        launch_url="${raw_url}"
        if [[ -n "$ticket" ]]; then
            if [[ "$launch_url" == *"?"* ]]; then
                launch_url="${launch_url}&ticket=${ticket}"
            else
                launch_url="${launch_url}?ticket=${ticket}"
            fi
        fi
    fi
    
    safe_su "am start -a android.intent.action.VIEW -d '${launch_url}' -p '${p}'"
    
    launch_times[$idx]=$(date +%s)
    if [[ -n "${ping_paths[$idx]}" ]]; then
        safe_su "rm \"${ping_paths[$idx]}\""
    fi
    ping_paths[$idx]=""
    
    statuses[$idx]="กำลังโหลด (Loading)"
    colors[$idx]="$C_YELLOW"
}

# ==========================================
# เมนู 1: Rejoin Loop (โหมด Direct Link + Deep Search)
# ==========================================
start_auto_rejoin() {
    clear
    show_header
    
    if [[ ! -s "$CONFIG_FILE" ]]; then
        echo -e "${C_RED}❌ ไม่พบข้อมูลจอ! กรุณาไปทำเมนู 2 หรือ 4 เพื่อตั้งค่าก่อน${C_RESET}"
        sleep 3
        return
    fi

    inject_lua_script

    stty onlcr sane 2>/dev/null
    clear
    show_header

    echo -e "${C_CYAN}--- Auto Rejoin Setup ---${C_RESET}"
    echo -e "${C_YELLOW}กรุณาเลือกรูปแบบการเข้าเกม (พิมพ์ 1 หรือ 2):${C_RESET}"
    echo -e "  ${C_GREEN}1.${C_RESET} Public Server (เซิร์ฟรวม / ใส่แค่ Place ID)"
    echo -e "  ${C_GREEN}2.${C_RESET} VIP Server (เซิร์ฟส่วนตัว / ใส่ลิงก์ VIP เต็มๆ)"
    echo ""
    read -p "🎯 เลือกโหมด: " mode_choice

    place_id=""
    raw_url=""

    if [[ "$mode_choice" == "1" ]]; then
        read -p "🎯 ใส่ Place ID ตัวเลข: " input_place
        place_id=$(echo "$input_place" | tr -d '\r\n ')
        if [[ -z "$place_id" ]]; then return; fi
        echo -e "${C_GREEN}✔️ บันทึก Place ID สำเร็จ!${C_RESET}"
        sleep 1
        
    elif [[ "$mode_choice" == "2" ]]; then
        read -p "🔗 วางลิงก์ VIP / Share Link ทั้งหมด: " input_place
        raw_url=$(echo "$input_place" | tr -d '\r\n ')
        if [[ -z "$raw_url" ]]; then return; fi
        echo -e "${C_GREEN}✔️ บันทึกลิงก์สำเร็จ! ระบบจะใช้ลิงก์นี้ดึงเข้าแมพโดยตรง${C_RESET}"
        sleep 2
    else
        echo -e "${C_RED}❌ เลือกโหมดไม่ถูกต้อง!${C_RESET}"
        sleep 2
        return
    fi

    read -p "⏳ หน่วงเวลาระหว่างเปิดจอรอบแรกกี่วิ? (แนะนำ 5-10): " delay_between
    if [[ ! "$delay_between" =~ ^[0-9]+$ ]]; then delay_between=7; fi

    pkgs=()
    unames=()
    
    while IFS=':' read -r pkg uname; do 
        pkg="${pkg//[$'\t\r\n ']/}"
        uname="${uname//[$'\t\r\n ']/}"
        
        if [[ -n "$pkg" ]]; then
            if [[ -z "$uname" ]]; then uname="Unknown"; fi
            pkgs+=("$pkg")
            unames+=("$uname")
        fi
    done < "$CONFIG_FILE"
    
    if (( ${#pkgs[@]} == 0 )); then
        echo -e "${C_RED}❌ ข้อมูลเสียหาย! กรุณาไปทำเมนู 2 ใหม่อีกครั้ง${C_RESET}"
        sleep 3
        return
    fi

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
        global_msg="${C_CYAN}👀 ระบบ Rejoin กำลังตรวจสอบ...${C_RESET}"
        current_time=$(date +%s)

        for i in "${!pkgs[@]}"; do
            pkg="${pkgs[$i]}"
            uname="${unames[$i]}"
            
            # 📌 แก้บั๊ก: เพิ่มความลึกในการค้นหาไฟล์ชีพจรเป็น 10
            if [[ -z "${ping_paths[$i]}" ]]; then
                local found_paths=$(su -c "find /storage/emulated/0 -maxdepth 10 -type f -iname 'ping_${uname}.txt' 2>/dev/null")
                local final_path=""
                for f in $found_paths; do
                    final_path="$f"
                    break
                done
                if [[ -n "$final_path" ]]; then ping_paths[$i]="$final_path"; fi
            fi

            if [[ -n "${ping_paths[$i]}" ]]; then
                last_ping=$(su -c "cat '${ping_paths[$i]}'" 2>/dev/null | tr -d '\r\n ')
                
                if [[ "$last_ping" == "DEAD" ]]; then
                    statuses[$i]="หลุด! (Error Msg)"
                    colors[$i]="$C_RED"
                    draw_dashboard
                    relaunch_pkg "$pkg" "$i"
                elif [[ "$last_ping" =~ ^[0-9]+$ ]]; then
                    diff=$((current_time - last_ping))
                    if (( diff > 60 )); then
                        statuses[$i]="หลุด! (Dead > 60s)"
                        colors[$i]="$C_RED"
                        draw_dashboard
                        relaunch_pkg "$pkg" "$i"
                    else
                        statuses[$i]="ออนไลน์ (${diff}s ก่อน)"
                        colors[$i]="$C_GREEN"
                    fi
                else
                    launched_at=${launch_times[$i]:-0}
                    wait_time=$((current_time - launched_at))
                    if (( wait_time > 150 )); then 
                        statuses[$i]="จอค้าง! (Timeout)"
                        colors[$i]="$C_RED"
                        draw_dashboard
                        relaunch_pkg "$pkg" "$i"
                    else
                        statuses[$i]="รอข้อมูล (${wait_time}s)"
                        colors[$i]="$C_YELLOW"
                    fi
                fi
            else
                launched_at=${launch_times[$i]:-0}
                wait_time=$((current_time - launched_at))
                if (( wait_time > 150 )); then 
                    statuses[$i]="จอค้าง! (Timeout)"
                    colors[$i]="$C_RED"
                    draw_dashboard
                    relaunch_pkg "$pkg" "$i"
                else
                    statuses[$i]="รอสคริปต์ (${wait_time}s)"
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
# ดักจับ Ctrl+C
# ==========================================
trap 'tput cnorm; clear; stty onlcr sane 2>/dev/null; exit' INT

# ==========================================
# เริ่มการทำงาน 
# ==========================================
check_root

# ==========================================
# เมนูหลัก 
# ==========================================
while true; do
    clear
    show_header
    echo -e "${C_CYAN}┌────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_CYAN}│${C_RESET}  ${C_GREEN}1${C_RESET}  Start Auto Rejoin   ${C_YELLOW}Smart System${C_RESET}                   ${C_CYAN}│${C_RESET}"
    echo -e "${C_CYAN}│${C_RESET}  ${C_GREEN}2${C_RESET}  Start Auto Setup    ${C_YELLOW}Account Binding${C_RESET}                ${C_CYAN}│${C_RESET}"
    echo -e "${C_CYAN}│${C_RESET}  ${C_GREEN}3${C_RESET}  Manage Webhook      ${C_YELLOW}Discord Autoexec${C_RESET}               ${C_CYAN}│${C_RESET}"
    echo -e "${C_CYAN}│${C_RESET}  ${C_GREEN}4${C_RESET}  Setup Cookie Login  ${C_YELLOW}Import & Auto Bind${C_RESET}             ${C_CYAN}│${C_RESET}"
    echo -e "${C_CYAN}│${C_RESET}  ${C_GREEN}5${C_RESET}  Run Cookie Login    ${C_YELLOW}Login to Home Screen${C_RESET}           ${C_CYAN}│${C_RESET}"
    echo -e "${C_CYAN}│${C_RESET}                                                        ${C_CYAN}│${C_RESET}"
    echo -e "${C_CYAN}│${C_RESET}  ${C_GREEN}0${C_RESET}  Exit                ${C_YELLOW}Close Tool${C_RESET}                     ${C_CYAN}│${C_RESET}"
    echo -e "${C_CYAN}└────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    read -p "select: " opt_main
    case $opt_main in
        1) start_auto_rejoin ;;
        2) start_auto_setup_menu ;;
        3) setup_webhook ;;
        4) setup_cookie ;;
        5) execute_cookie_login ;;
        0) clear; tput cnorm; stty onlcr sane 2>/dev/null; exit 0 ;;
        *) echo -e "${C_RED}Invalid option!${C_RESET}"; sleep 1 ;;
    esac
done

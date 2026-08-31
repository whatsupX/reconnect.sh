#!/bin/bash

# กำหนดค่าสี
C_CYAN='\e[36m'
C_GREEN='\e[32m'
C_YELLOW='\e[33m'
C_RED='\e[31m'
C_RESET='\e[0m'

# ฟังก์ชันแสดงโลโก้
show_header() {
    clear
    echo -e "${C_CYAN}"
    echo " _ __ ___  ___ ___  _ __  _ __   ___  ___| |_"
    echo "| '__/ _ \/ __/ _ \| '_ \| '_ \ / _ \/ __| __|"
    echo "| | |  __/ (_| (_) | | | | | | |  __/ (__| |_"
    echo "|_|  \___|\___\___/|_| |_|_| |_|\___|\___|\__|"
    echo "              Made by Mist v6.2.6"
    echo -e "${C_RESET}"
}

# เมนู 1: Auto Rejoin
menu_auto_rejoin() {
    while true; do
        show_header
        echo -e "${C_CYAN}Auto Rejoin Options:${C_RESET}"
        echo "------------------------"
        echo -e "${C_CYAN}1.${C_RESET} Freemium"
        echo -e "${C_CYAN}0.${C_RESET} Back to Main Menu"
        echo ""
        read -p "Select an option: " opt_rejoin
        
        case $opt_rejoin in
            1)
                read -p "A saved configuration was found. Would you like to load it? (Y/N) (Default: N): " load_config
                show_header
                echo "             Package Operation Status"
                echo "============================================================"
                printf "| %-12s | %-16s | %-22s |\n" "Username" "Package" "Status"
                echo "============================================================"
                printf "| %-12s | %-16s | ${C_GREEN}%-22s${C_RESET} |\n" "T********8" "roblox.clientv" "Successfully Killed..."
                printf "| %-12s | %-16s | ${C_GREEN}%-22s${C_RESET} |\n" "A********1" "roblox.clientw" "Successfully Killed..."
                printf "| %-12s | %-16s | ${C_GREEN}%-22s${C_RESET} |\n" "Z********9" "roblox.clientx" "Successfully Killed..."
                echo "============================================================"
                echo ""
                read -p "Press Enter to return..."
                ;;
            0) return ;;
            *) echo -e "${C_RED}Invalid option!${C_RESET}"; sleep 1 ;;
        esac
    done
}

# เมนู 2: Auto Setup
menu_auto_setup() {
    while true; do
        show_header
        echo -e "${C_CYAN}Start Auto Setup${C_RESET}"
        echo "------------------------"
        echo -e "${C_CYAN}Setup Options:${C_RESET}"
        echo -e "${C_CYAN}1.${C_RESET} Automatic Setup (Requires Root)"
        echo -e "${C_CYAN}2.${C_RESET} Manual Setup (No Root Required)"
        echo -e "${C_CYAN}0.${C_RESET} Back to Main Menu"
        echo ""
        read -p "Select an option: " opt_setup
        
        case $opt_setup in
            1)
                echo -e "${C_YELLOW}Checking Root access...${C_RESET}"
                sleep 2
                ;;
            2)
                show_header
                echo -e "${C_CYAN}Manual Setup (No Root Required)${C_RESET}"
                echo ""
                echo -e "${C_CYAN}Detected Roblox Packages:${C_RESET}"
                echo "No packages automatically detected"
                echo ""
                echo -e "${C_CYAN}Prefix-Based Detection:${C_RESET}"
                echo "Enter a prefix to find all packages starting with it (e.g., 'tt.nobody')"
                read -p "Enter package prefix (or leave blank to skip): " pkg_prefix
                echo -e "${C_GREEN}Searching for packages...${C_RESET}"
                sleep 2
                ;;
            0) return ;;
            *) echo -e "${C_RED}Invalid option!${C_RESET}"; sleep 1 ;;
        esac
    done
}

# เมนูหลัก
while true; do
    show_header
    echo -e "${C_CYAN}Available Features:${C_RESET}"
    echo -e "${C_CYAN}1.${C_RESET} Start Auto Rejoin"
    echo -e "${C_CYAN}2.${C_RESET} Start Auto Setup"
    echo -e "${C_CYAN}3.${C_RESET} Add script to autoexecute folder"
    echo -e "${C_CYAN}4.${C_RESET} Use Discord Webhook"
    echo -e "${C_CYAN}5.${C_RESET} Miscellaneous"
    echo ""
    echo -e "${C_CYAN}00.${C_RESET} Exit"
    echo ""
    read -p "Select an option: " opt_main

    case $opt_main in
        1) menu_auto_rejoin ;;
        2) menu_auto_setup ;;
        3) echo "Autoexecute feature coming soon..."; sleep 1 ;;
        4) echo "Webhook feature coming soon..."; sleep 1 ;;
        5) echo "Misc feature coming soon..."; sleep 1 ;;
        00) clear; exit 0 ;;
        *) echo -e "${C_RED}Invalid option!${C_RESET}"; sleep 1 ;;
    esac
done

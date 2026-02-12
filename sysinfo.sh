#!/bin/bash
# ====================================================
# @Author: Engeryu
# @Version: 2.0.0 (Architect Edition)
# Description: Modern System Information Tool.
#              Supports Interactive Menu AND JSON Output for Monitoring.
# ====================================================

# --- Configuration & Globals ---
VERSION="2.0.0"
JSON_OUTPUT=false
INTERACTIVE_MODE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Helper Functions ---

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Data Gathering Functions (The "Backend") ---

get_cpu_info() {
    if [ "$JSON_OUTPUT" = true ]; then
        local model=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
        local cores=$(lscpu | grep "^CPU(s):" | cut -d: -f2 | xargs)
        echo "\"cpu_model\": \"$model\", \"cpu_cores\": $cores"
    else
        lscpu | grep -E 'Model name|Socket|Thread|NUMA|CPU\(s\)'
    fi
}

get_ram_info() {
    # Uses free -m for MB calculation
    local total=$(free -m | awk '/Mem:/ {print $2}')
    local used=$(free -m | awk '/Mem:/ {print $3}')
    local free=$(free -m | awk '/Mem:/ {print $4}')

    if [ "$JSON_OUTPUT" = true ]; then
        echo "\"ram_total_mb\": $total, \"ram_used_mb\": $used, \"ram_free_mb\": $free"
    else
        echo -e "${GREEN}RAM Usage:${NC} Used: ${used}MB / Total: ${total}MB"
        free -h
    fi
}

get_disk_info() {
    # Focus on Root partition for monitoring
    local root_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    local root_total=$(df -h / | awk 'NR==2 {print $2}')

    if [ "$JSON_OUTPUT" = true ]; then
        echo "\"disk_root_usage_percent\": $root_usage, \"disk_root_total\": \"$root_total\""
    else
        echo -e "${GREEN}Disk Usage (Root):${NC} $root_usage% used of $root_total"
        df -h | grep -E '^Filesystem|/dev/'
    fi
}

get_network_info() {
    # Modern approach using 'ip' instead of ifconfig
    local ip_addr=$(ip -4 a show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n 1)
    local gateway=$(ip r | grep default | awk '{print $3}')

    if [ "$JSON_OUTPUT" = true ]; then
        echo "\"ip_address\": \"$ip_addr\", \"gateway\": \"$gateway\""
    else
        echo -e "${GREEN}IP Address:${NC} $ip_addr"
        echo -e "${GREEN}Gateway:${NC} $gateway"
        echo -e "${GREEN}Open Ports (Listening):${NC}"
        # Replacement of legacy 'netstat' with modern 'ss'
        ss -tuln | grep LISTEN
    fi
}

# --- Output Modes ---

generate_full_json() {
    echo "{"
    echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
    echo "  \"hostname\": \"$(hostname)\","
    echo "  \"system\": {"
    get_cpu_info
    echo "  },"
    echo "  \"memory\": {"
    get_ram_info
    echo "  },"
    echo "  \"storage\": {"
    get_disk_info
    echo "  },"
    echo "  \"network\": {"
    get_network_info
    echo "  }"
    echo "}"
}

# --- Legacy Interactive Menu (Refactored) ---

pause() {
    read -rp $'\nPress enter to continue...'
}

print_header() {
    clear
    echo -e "${CYAN}======================================="
    echo -e " $1"
    echo -e "=======================================${NC}"
}

run_interactive_menu() {
    while true; do
        print_header "SysInfo V2 - Main Menu"
        echo "1) Hardware Stats"
        echo "2) Network Stats"
        echo "3) Process Management"
        echo "4) Generate JSON Report (New)"
        echo "5) Exit"
        read -p $'\nEnter choice: ' choice
        case "$choice" in
            1)
                print_header "Hardware";
                get_cpu_info; echo ""; get_ram_info; echo ""; get_disk_info;
                pause ;;
            2)
                print_header "Network";
                get_network_info;
                pause ;;
            3)
                print_header "Processes";
                top -n 1 -b | head -n 10; # Non-interactive top for safety
                echo -e "\n(Run 'top' manually for interaction)";
                pause ;;
            4)
                JSON_OUTPUT=true; generate_full_json; JSON_OUTPUT=false;
                pause ;;
            5) exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}"; pause ;;
        esac
    done
}

# --- Main Logic ---

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -i, --interactive   Run the interactive menu (Legacy mode)"
    echo "  -j, --json          Output system metrics in JSON format (DevOps mode)"
    echo "  -h, --help          Show this help message"
}

# Argument Parsing
if [ $# -eq 0 ]; then
    # Default behavior if no args: Help (to encourage CLI usage) or Interactive
    # Let's default to interactive for now to not break your habits
    run_interactive_menu
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--interactive) INTERACTIVE_MODE=true ;;
        -j|--json) JSON_OUTPUT=true ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown parameter: $1"; usage; exit 1 ;;
    esac
    shift
done

if [ "$INTERACTIVE_MODE" = true ]; then
    run_interactive_menu
elif [ "$JSON_OUTPUT" = true ]; then
    generate_full_json
else
    usage
fi


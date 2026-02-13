#!/bin/bash
# @Author: Engeryu
# @Description: System Information Tool - Production Ready
# @Features: Modular, JSON, Logging, WSL-Friendly, Health Checks, Docker

# ==========================================
# 1. CONFIGURATION
# ==========================================

LOG_FILE="$HOME/sysinfo.log"
INTERACTIVE=true
JSON_MODE=false
DO_LOG=false
HEALTH_CHECK=false

# Thresholds for Alerts (Percentage)
LIMIT_CPU=85
LIMIT_MEM=90
LIMIT_DISK=90

# Module Flags
SHOW_ALL=true
SHOW_OS=false; SHOW_CPU=false; SHOW_MEM=false
SHOW_DISK=false; SHOW_NET=false; SHOW_PROC=false
SHOW_DOCKER=false

if [ ! -t 1 ]; then INTERACTIVE=false; fi

# Colors
if [ "$INTERACTIVE" = true ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; PURPLE=''; CYAN=''; BOLD=''; NC=''
fi

# ==========================================
# 2. HELPER FUNCTIONS
# ==========================================

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --json       Output JSON format"
    echo "  --log        Save to log file"
    echo "  --check      Run health checks (returns exit code 1 if critical)"
    echo "  --no-color   Disable colors"
    echo ""
    echo "Modules: --full, --os, --cpu, --mem, --disk, --net, --proc, --docker"
    exit 0
}

draw_bar() {
    local percent=$1
    if [ "$INTERACTIVE" = false ]; then echo "${percent}%"; return; fi
    local width=20
    local num_filled=$((percent * width / 100))
    local num_empty=$((width - num_filled))
    local color=$GREEN
    [ "$percent" -ge 70 ] && color=$YELLOW
    [ "$percent" -ge 90 ] && color=$RED
    local bar=""
    for ((i=0; i<num_filled; i++)); do bar+="█"; done
    for ((i=0; i<num_empty; i++)); do bar+="░"; done
    echo -e "${color}[${bar}] ${percent}%${NC}"
}

section_header() {
    local title="$1"
    if [ "$INTERACTIVE" = true ]; then echo -e "\n${PURPLE}=== $title ===${NC}"; else echo -e "\n--- $title ---"; fi
}

# ==========================================
# 3. TEXT MODULES
# ==========================================

mod_os() {
    section_header "🐧 SYSTEM INFO"
    local hostname=$(hostname)
    local os=$(grep -E '^(PRETTY_NAME)' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    [ -z "$os" ] && os=$(uname -s)
    local kernel=$(uname -r)
    local uptime=$(uptime -p)
    printf "  %-15s : %s\n" "Hostname" "$hostname"
    printf "  %-15s : %s\n" "OS" "$os"
    printf "  %-15s : %s\n" "Kernel" "$kernel"
    printf "  %-15s : %s\n" "Uptime" "$uptime"
}

mod_cpu() {
    section_header "🧠 CPU STATS"
    local model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
    local cores=$(grep -c 'processor' /proc/cpuinfo)
    local load=$(cat /proc/loadavg | awk '{print $1 ", " $2 ", " $3}')
    # Snapshot CPU calc
    local cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print int(usage)}')

    printf "  %-15s : %s\n" "Model" "$model"
    printf "  %-15s : %s Cores\n" "Cores" "$cores"
    printf "  %-15s : %s\n" "Load Avg" "$load"
    printf "  %-15s : " "Usage"
    draw_bar "$cpu_usage"
}

mod_mem() {
    section_header "💾 MEMORY"
    local total=$(free -m | awk '/Mem:/ {print $2}')
    local used=$(free -m | awk '/Mem:/ {print $3}')
    local percent=$((used * 100 / total))
    printf "  %-15s : %s MB / %s MB\n" "RAM Usage" "$used" "$total"
    printf "  %-15s : " "Status"
    draw_bar "$percent"
}

mod_disk() {
    section_header "💿 DISK STORAGE"
    printf "  %-30s %-10s %-25s\n" "MOUNT" "SIZE" "USAGE"

    df -hP | awk -v u_home="$HOME" '$6 == "/" || $6 == u__home || $6 == "/usr" || $6 ~ /^\/mnt\// || $6 ~ /^\/media\// || $6 ~ /docker/ {print $2, $5, $6}' | while read -r size used_str mount; do

        if [[ "$mount" == "/mnt/wsl" ]] || [[ "$mount" == "/mnt/wslg"* ]]; then
            continue
        fi

        local used_pct=${used_str%\%}
        [[ "$used_pct" =~ ^[0-9]+$ ]] || continue

        local display_mount="$mount"
        if [ ${#display_mount} -gt 29 ]; then
            display_mount="...${mount: -26}"
        fi

        printf "  %-30s %-10s " "$display_mount" "$size"
        draw_bar "$used_pct"
    done
}

mod_net() {
    section_header "🌐 NETWORK"
    local ip_local=$(hostname -I | awk '{print $1}')
    local ports=$(ss -tuln | awk 'NR>1 {print $5}' | cut -d: -f2 | sort -n | uniq | tr '\n' ',' | sed 's/,$//')
    [ -z "$ports" ] && ports="None"
    printf "  %-15s : %s\n" "Local IP" "$ip_local"
    printf "  %-15s : %s\n" "Open Ports" "$ports"
}

mod_docker() {
    section_header "🐳 DOCKER CONTAINERS"
    if command -v docker &> /dev/null; then
        if [ "$INTERACTIVE" = true ]; then
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -n 6
        else
            docker ps --format "{{.Names}} - {{.Status}}" | head -n 6
        fi
        local count=$(docker ps -q | wc -l)
        echo "  Total Running: $count"
    else
        echo "  Docker not installed or not running."
    fi
}

mod_proc() {
    section_header "⚙️ TOP PROCESSES"
    if [ "$INTERACTIVE" = true ]; then echo -e "${BOLD}  PID   USER       %CPU %MEM COMMAND${NC}"; else echo "  PID   USER       %CPU %MEM COMMAND"; fi
    ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 6 | tail -n 5 | awk '{printf "  %-5s %-10s %-4s %-4s %s\n", $1, $2, $3, $4, $5}'
}

# ==========================================
# 4. HEALTH CHECK ENGINE (Alerting)
# ==========================================

run_health_check() {
    local exit_code=0
    echo -e "\n${BOLD}🏥 SYSTEM HEALTH CHECK${NC}"

    # Check CPU
    local cpu=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print int(usage)}')
    if [ "$cpu" -ge "$LIMIT_CPU" ]; then
        echo -e "  [${RED}FAIL${NC}] CPU Critical: ${cpu}% (Limit: $LIMIT_CPU%)"
        exit_code=1
    else
        echo -e "  [${GREEN}OK${NC}] CPU: ${cpu}%"
    fi

    # Check MEM
    local mem_total=$(free -m | awk '/Mem:/ {print $2}')
    local mem_used=$(free -m | awk '/Mem:/ {print $3}')
    local mem_pct=$((mem_used * 100 / mem_total))
    if [ "$mem_pct" -ge "$LIMIT_MEM" ]; then
        echo -e "  [${RED}FAIL${NC}] Memory Critical: ${mem_pct}% (Limit: $LIMIT_MEM%)"
        exit_code=1
    else
        echo -e "  [${GREEN}OK${NC}] Memory: ${mem_pct}%"
    fi

    # Check DISK (Root)
    local disk=$(df / | grep / | awk '{print $5}' | tr -d '%')
    if [ "$disk" -ge "$LIMIT_DISK" ]; then
        echo -e "  [${RED}FAIL${NC}] Disk (/) Critical: ${disk}% (Limit: $LIMIT_DISK%)"
        exit_code=1
    else
        echo -e "  [${GREEN}OK${NC}] Disk (/): ${disk}%"
    fi

    if [ $exit_code -eq 0 ]; then
        echo -e "\n${GREEN}System Healthy.${NC}"
    else
        echo -e "\n${RED}System Requires Attention!${NC}"
    fi
    exit $exit_code
}

# ==========================================
# 5. JSON ENGINE
# ==========================================

generate_pretty_json() {
    local hostname=$(hostname)
    local ip=$(hostname -I | awk '{print $1}')
    local os=$(grep -E '^(PRETTY_NAME)' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    local cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
    local cores=$(grep -c 'processor' /proc/cpuinfo)
    local mem_total=$(free -m | awk '/Mem:/ {print $2}')
    local mem_used=$(free -m | awk '/Mem:/ {print $3}')

    local docker_json="[]"
    if command -v docker &> /dev/null; then
         docker_json=$(docker ps --format '{{.Names}}|{{.Status}}' | awk '
         BEGIN { printf "[" }
         { if (NR>1) printf ","; printf "{\"name\":\""$1"\",\"status\":\""$2"\"}"; }
         END { printf "]" }' | sed 's/|/","/g')
    fi

    local disk_json=$(df -hP | grep -vE '^Filesystem|tmpfs|cdrom|overlay|/sys|/proc' | awk -v u_home="$HOME" '
    BEGIN { count=0 }
    {
        p_col = 0
        for (i=1; i<=NF; i++) { if ($i ~ /^[0-9]+%$/) { p_col = i; break } }

        if (p_col > 0) {
            size = $(p_col - 3)
            pct_str = $(p_col)
            gsub("%", "", pct_str)

            mount = ""
            for (j=p_col+1; j<=NF; j++) { mount = mount $j " "; }
            sub(/ $/, "", mount)

            # FILTRE JSON : Racine, Home, User Home, Mnt, Media, Docker
            if (mount == "/" || mount == "/home" || mount == u_home || mount ~ /^\/mnt\// || mount ~ /^\/media\// || tolower(mount) ~ /docker/) {

                if (mount != "/mnt/wsl" && mount !~ /^\/mnt\/wslg/) {
                    if (count > 0) printf ",\n";
                    printf "    { \"mount\": \"%s\", \"size\": \"%s\", \"used_pct\": %s }", mount, size, pct_str
                    count++
                }
            }
        }
    }')

    local proc_json=$(ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 6 | tail -n 5 | awk '
    BEGIN { count=0 }
    {
        if (count > 0) printf ",\n";
        printf "    { \"pid\": %s, \"user\": \"%s\", \"cpu\": %s, \"mem\": %s, \"cmd\": \"%s\" }", $1, $2, $3, $4, $5;
        count++;
    }')

    cat <<EOF
{
  "system": { "hostname": "$hostname", "os": "$os", "ip": "$ip" },
  "resources": {
    "cpu": { "model": "$cpu_model", "cores": $cores },
    "memory_mb": { "total": $mem_total, "used": $mem_used }
  },
  "disks": [
$disk_json
  ],
  "docker_containers": $docker_json,
  "top_processes": [
$proc_json
  ]
}
EOF
}

# ==========================================
# 6. EXECUTION
# ==========================================

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --help) usage ;;
        --json) JSON_MODE=true; shift ;;
        --log) DO_LOG=true; shift ;;
        --check) HEALTH_CHECK=true; shift ;;
        --no-color) INTERACTIVE=false; RED=''; GREEN=''; NC=''; shift ;;
        --full) SHOW_ALL=true; shift ;;
        --os) SHOW_OS=true; SHOW_ALL=false; shift ;;
        --cpu) SHOW_CPU=true; SHOW_ALL=false; shift ;;
        --mem) SHOW_MEM=true; SHOW_ALL=false; shift ;;
        --disk) SHOW_DISK=true; SHOW_ALL=false; shift ;;
        --net) SHOW_NET=true; SHOW_ALL=false; shift ;;
        --proc) SHOW_PROC=true; SHOW_ALL=false; shift ;;
        --docker) SHOW_DOCKER=true; SHOW_ALL=false; shift ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

run_modules() {
    if [ "$SHOW_ALL" = true ] || [ "$SHOW_OS" = true ]; then mod_os; fi
    if [ "$SHOW_ALL" = true ] || [ "$SHOW_CPU" = true ]; then mod_cpu; fi
    if [ "$SHOW_ALL" = true ] || [ "$SHOW_MEM" = true ]; then mod_mem; fi
    if [ "$SHOW_ALL" = true ] || [ "$SHOW_DISK" = true ]; then mod_disk; fi
    if [ "$SHOW_ALL" = true ] || [ "$SHOW_NET" = true ]; then mod_net; fi
    if [ "$SHOW_ALL" = true ] || [ "$SHOW_DOCKER" = true ]; then mod_docker; fi
    if [ "$SHOW_ALL" = true ] || [ "$SHOW_PROC" = true ]; then mod_proc; fi
}

if [ "$HEALTH_CHECK" = true ]; then
    run_health_check
elif [ "$JSON_MODE" = true ]; then
    generate_pretty_json
elif [ "$DO_LOG" = true ]; then
    INTERACTIVE=false; RED=''; GREEN=''; NC=''
    echo "Writing log to $LOG_FILE..."
    {
        echo "========== REPORT $(date) =========="
        run_modules
        echo ""
    } >> "$LOG_FILE"
    echo "Done."
else
    if [ "$INTERACTIVE" = true ]; then
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║     SYSADMIN MONITORING DASHBOARD        ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    fi
    run_modules
    echo ""
    if [ "$INTERACTIVE" = true ]; then echo -e "${CYAN}Scan Complete.${NC}"; fi
fi


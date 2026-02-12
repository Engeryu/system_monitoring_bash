# 🖥️ System Information Toolkit (Bash) v2.0

> **Architect Edition:** A modern, hybrid system analysis tool capable of both interactive exploration and automated JSON metrics collection.

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Version](https://img.shields.io/badge/Version-2.0.0-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## 🚀 Features & Evolution

This project has evolved from a simple administration script (2018) to a robust system monitoring agent (2025+). It now supports two distinct modes of operation:

### 1. 🛠️ Interactive Admin Mode (Legacy)
Designed for manual system checks and exploration via a user-friendly menu.
- **Hardware:** CPU model/cores, RAM usage, Disk partition stats.
- **Network:** IP configuration, Gateway, Open ports (via `ss`).
- **Process:** Real-time monitoring via `top`.

### 2. 🤖 DevOps Automation Mode (New in v2.0)
Designed for monitoring pipelines, logging, and API integration.
- **JSON Output:** Generates machine-readable system metrics.
- **Pipeline Ready:** Can be piped into `jq`, log files, or monitoring dashboards.
- **Non-Interactive:** Runs silently without user input.

---

## 🛠️ Requirements

The script uses standard Linux utilities. For full functionality, ensure the following packages are installed:

- **Core:** `bash`, `awk`, `grep`, `sed`
- **Network:** `ip` (iproute2), `ss` (iproute2)
- **Hardware:** `lscpu`, `free`, `df`

> **Note:** Legacy dependencies like `netstat` and `nslookup` have been replaced by modern alternatives (`ss`, `ip`) in v2.0.

---

## 📦 Installation & Usage

```bash
# 1. Clone the repository
git clone [https://github.com/Engeryu/My_Sysinfo_Bash.git](https://github.com/Engeryu/My_Sysinfo_Bash.git)
cd My_Sysinfo_Bash

# 2. Make executable
chmod +x my_sysinfo_v2.sh
```

### Option A: Interactive Mode (The Legacy Way)

Perfect for beginners
```bash
./my_sysinfo_v2.sh -i
# or simply
./my_sysinfo_v2.sh
```

Preview:

```bash
=======================================
 SysInfo V2 - Main Menu
=======================================
1) Hardware Stats
2) Network Stats
3) Process Management
4) Generate JSON Report (New)
5) Exit
```

### Option B: DevOps Mode (The Modern Way)

Perfect for cron jobs, logging or passing data to other tools
```bash
# Output raw JSON to console
./my_sysinfo_v2.sh --json

# Example: Save state to log file
./my_sysinfo_v2.sh --json >> /var/log/sysinfo.json

# Example: Extract specific metric (requires jq)
./my_sysinfo_v2.sh --json | jq '.memory.ram_used_mb'
```

JSON Output Example:

```bash
{
  "timestamp": "2026-02-12T10:30:00Z",
  "hostname": "production-server-01",
  "system": {
    "cpu_model": "AMD Ryzen 7 5800X",
    "cpu_cores": 16
  },
  "memory": {
    "ram_total_mb": 32000,
    "ram_used_mb": 14500,
    "ram_free_mb": 17500
  },
  "storage": {
    "disk_root_usage_percent": 45,
    "disk_root_total": "500G"
  }
}
```

---

## 🤝 Contributions

Contributions are welcome ! Whether it's adding new metrics to the JSON output
or optimizing the bash logic, feel free to fork and submit a PR.

---

*Authored by Engeryu - 2018-2026*

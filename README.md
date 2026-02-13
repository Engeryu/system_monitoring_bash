# 🖥️ SysInfo - Production Ready System Monitor

> **A robust, modular, and dependency-free system monitoring tool written in Bash.**
> Designed for **SysAdmins** (Interactive Dashboard) and **DevOps** (JSON Automation & Health Checks).

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20WSL-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

## 🌟 Key Features

* **📊 Interactive Dashboard:** Rich visual output with progress bars, color-coded statuses, and auto-refreshing metrics.
* **🧠 Smart Disk Filtering:** Automatically detects and displays relevant storage:
    * Root (`/`) & System (`/home`, `/usr`)
    * External Media (`/media/*`, `/mnt/usb`...)
    * Windows Drives (WSL: `/mnt/c`, `/mnt/d`...)
    * Docker Volumes
    * *Ignores system noise (tmpfs, loops, WSL internal mounts).*
* **🤖 DevOps Ready (JSON):** Generates clean, parsed JSON output for ingestion by monitoring stacks (ELK, Datadog, Zabbix).
* **🏥 Health Checks:** Integrated alerting system returning exit codes (`0`/`1`) for CI/CD pipelines or cron jobs.
* **🐳 Docker Support:** Auto-detects running containers and stats.

## 📦 Installation

No installation required. Zero external dependencies (uses standard tools: `df`, `awk`, `grep`, `ps`, `free`).

```bash
# 1. Clone the repository
git clone [https://github.com/yourusername/sysinfo.git](https://github.com/yourusername/sysinfo.git)
cd sysinfo

# 2. Make executable
chmod +x sysinfo.sh

# 3. Run
./sysinfo.sh
````

## 🛠️ Usage Scenarios

### 1\. The SysAdmin Check (Dashboard)

Simply run the script to see the visual report. Ideal for login messages (`.bashrc`) or manual checks.

Bash

```
./sysinfo.sh
```

_Displays: OS Info, CPU Load, RAM, Disk Usage (Smart Filtered), Network, Docker, Top Processes._

### 2\. The DevOps Export (JSON)

Export full system metrics to a monitoring tool or API.

Bash

```
./sysinfo.sh --json > metrics.json
```

_Output is strictly formatted JSON, ready for parsing._

### 3\. The Health Check (Alerting)

Use this in cron jobs or CI pipelines. It checks CPU (>85%), RAM (>90%), and Disk (>90%).

-   **Returns Exit Code 0:** System Healthy.
-   **Returns Exit Code 1:** Critical Threshold Exceeded.

Bash

```
if ./sysinfo.sh --check; then
    echo "✅ System Green"
else
    echo "❌ CRITICAL ALERT: Check logs!"
    # Trigger email or Slack webhook here
fi
```

### 4\. The Archivist (Logging)

Save the report to a log file (automatically strips ANSI colors for readability).

Bash

```
./sysinfo.sh --log
# Output appended to ~/sysinfo.log
```

### 5\. Modular Execution

Only need specific info? Use flags to run specific modules.

Bash

```
./sysinfo.sh --cpu --mem --disk
```

## 🔌 External Storage (WSL Specifics)

This tool is optimized for **WSL (Windows Subsystem for Linux)**. It automatically filters out WSL internal mounts to show you what matters.

## ⚙️ Configuration

You can adjust the alert thresholds directly in the script header:

Bash

```
# Thresholds for Alerts (Percentage)
LIMIT_CPU=85
LIMIT_MEM=90
LIMIT_DISK=90
```

## 📝 Command Reference

| Flag | Description |
| --- | --- |
| `--help` | Show available commands |
| `--json` | Output in JSON format (Full Data) |
| `--check` | Run Health Checks (Quiet mode, returns exit code) |
| `--log` | Append report to `~/sysinfo.log` |
| `--no-color` | Force disable ANSI colors |
| `--full` | Run all modules (Default) |
| `--os` | Show OS & Kernel info |
| `--cpu` | Show CPU Model, Cores & Load |
| `--mem` | Show RAM Usage |
| `--disk` | Show Storage (Smart Filter: Root, Home, Mnt, Media, Docker) |
| `--net` | Show IP, Interface & Open Ports |
| `--docker` | Show Docker container stats |
| `--proc` | Show Top 5 Processes |

* * *


📝 Credits
----------

* **Author:** Engeryu
* **Concept:** All-in-one System Information solution

* * * * *


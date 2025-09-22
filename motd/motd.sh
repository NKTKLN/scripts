#!/bin/bash

# ========================================================
# MOTD System Status Script
# ========================================================
#
# Description:
# This script displays a colorful and informative Message of the Day (MOTD)
# when you log in to your server. It shows system load, CPU and memory usage,
# disk status, available updates, Docker containers, last SSH login, IP address,
# active users, and zombie processes.
#
# Requirements:
# 1. Linux system (Debian/Ubuntu recommended).
# 2. Utilities: awk, free, df, ps, last, hostname, bc.
# 3. For update info: APT package manager.
# 4. For Docker info: Docker installed (optional).
#
# Configuration:
# 1. Copy this script to /etc/profile.d/ for automatic execution on login:
#    sudo cp motd.sh /etc/profile.d/motd.sh
#    sudo chmod +x /etc/profile.d/motd.sh
# 2. The script will run for all users on login (SSH or terminal).
#
# Variables to Configure:
# - No manual configuration required. All values are detected automatically.
#
# Features:
# - System Load: 1, 5, and 30 minute averages.
# - CPU Usage: Color-coded based on usage.
# - Memory Usage: Color-coded, shows used/total and percent.
# - Disk Usage: Displays main and mounted disks.
# - Available Updates: Number of upgradable packages (APT).
# - Docker Status: Running/stopped containers (if Docker installed).
# - Last SSH Login: Last SSH login info.
# - Server IP: Main IP address.
# - Active Users: Number of logged-in users.
# - Tasks & Zombies: Total and zombie processes.
#
# ========================================================

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
WHITE="\e[97m"
RESET="\e[0m"

echo -e ""

# System Load
LOAD=$(uptime | awk -F'load average:' '{print $2}' | sed 's/,//g')
LOAD_1=$(echo $LOAD | awk '{print $1}')
LOAD_5=$(echo $LOAD | awk '{print $2}')
LOAD_30=$(echo $LOAD | awk '{print $3}')
echo -e "${CYAN}Load:${RESET} ${WHITE}$LOAD_1${RESET} (1 min) • ${WHITE}$LOAD_5${RESET} (5 min) • ${WHITE}$LOAD_30${RESET} (30 min)"

# CPU Usage (Correct Calculation Based on /proc/stat)
CPU_IDLE=$(awk '/cpu / {print $5}' /proc/stat)
CPU_TOTAL=$(awk '/cpu / {print $2+$3+$4+$5+$6+$7+$8}' /proc/stat)
CPU_USAGE=$((100 - (CPU_IDLE * 100 / CPU_TOTAL)))

if (( CPU_USAGE < 30 )); then
    CPU_COLOR=$GREEN
elif (( CPU_USAGE >= 30 && CPU_USAGE <= 75 )); then
    CPU_COLOR=$YELLOW
else
    CPU_COLOR=$RED
fi

echo -e "${CYAN}CPU Usage:${RESET} ${CPU_COLOR}$CPU_USAGE%${RESET}"

# Memory Usage (Color Based on Usage)
MEMORY_TOTAL=$(free -m | awk 'NR==2{print $2}')
MEMORY_USED=$(free -m | awk 'NR==2{print $3}')
MEMORY_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($MEMORY_USED/$MEMORY_TOTAL)*100}")

if (( $(echo "$MEMORY_PERCENT < 30" | bc -l) )); then
    MEM_COLOR=$GREEN
elif (( $(echo "$MEMORY_PERCENT >= 30 && $MEMORY_PERCENT <= 75" | bc -l) )); then
    MEM_COLOR=$YELLOW
else
    MEM_COLOR=$RED
fi

echo -e "${CYAN}Memory Usage:${RESET} ${MEM_COLOR}${MEMORY_USED}/${MEMORY_TOTAL}MB (${MEMORY_PERCENT}%)${RESET}"

# Disk Usage
echo -e "\e[36mDisk usage:\e[0m"

df -h --output=source,pcent,target | grep -E '^/dev' | while read line; do
  DEVICE=$(echo $line | awk '{print $1}')
  USAGE=$(echo $line | awk '{print $2}')
  MOUNT_POINT=$(echo $line | awk '{print $3}')

  if [[ "$MOUNT_POINT" == "/" ]]; then
    echo -e "  • \e[37mMain disk: ${USAGE}\e[0m"
  elif [[ "$MOUNT_POINT" == /mnt/* ]]; then
    FOLDER_NAME=$(basename "$MOUNT_POINT")
    echo -e "  • \e[37m${FOLDER_NAME}: ${USAGE}\e[0m"
  fi
done

# Available Updates
if command -v apt >/dev/null; then
  UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
  if [ "$UPDATES" -gt 0 ]; then
    echo -e "${CYAN}Available Updates:${RESET} ${WHITE}$UPDATES packages${RESET}"
  fi
fi

# Docker Status (Show only if Installed)
if command -v docker >/dev/null; then
  DOCKER_RUNNING=$(docker ps -q | wc -l)
  DOCKER_TOTAL=$(docker ps -aq | wc -l)
  DOCKER_STOPPED=$((DOCKER_TOTAL - DOCKER_RUNNING))

  if [ "$DOCKER_STOPPED" -gt 0 ]; then
    echo -e "${CYAN}Docker:${RESET} ${GREEN}$DOCKER_RUNNING running${RESET} • ${RED}$DOCKER_STOPPED stopped${RESET}"
  else
    echo -e "${CYAN}Docker:${RESET} ${GREEN}$DOCKER_RUNNING running${RESET}"
  fi
fi

# Last SSH Login
LAST_SSH=$(last -i | grep -m1 "ssh" | awk '{print $1, $3, $5, $6, $7}')
if [ -n "$LAST_SSH" ]; then
    echo -e "${CYAN}Last SSH Login:${RESET} ${WHITE}$LAST_SSH${RESET}"
fi

# Current IP
IP=$(hostname -I | awk '{print $1}')
echo -e "${CYAN}Server IP:${RESET} ${WHITE}$IP${RESET}"

# Active Users
USERS=$(who | wc -l)
echo -e "${CYAN}Active Users:${RESET} ${WHITE}$USERS${RESET}"

# Task & Zombie Processes
TASKS=$(ps aux --no-heading | wc -l)
ZOMBIES=$(ps aux | awk '{if ($8 == "Z") print $0}' | wc -l)
echo -e "${CYAN}Total Tasks:${RESET} ${WHITE}$TASKS${RESET}"

if [ "$ZOMBIES" -gt 0 ]; then
    echo -e "${CYAN}Zombie Tasks:${RESET} ${RED}$ZOMBIES${RESET}"
fi

echo -e ""
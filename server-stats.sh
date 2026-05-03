#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'; RESET='\033[0m'
sep() { printf '%.0s─' {1..50}; printf '\n'; }
header() { echo -e "\n${BOLD}$1${RESET}"; sep; }

# ── 1. CPU 사용률 ────────────────────────────────────────
header "CPU Usage"
read_cpu() { awk '/^cpu /{print $2,$3,$4,$5,$6,$7,$8}' /proc/stat; }
r1=$(read_cpu); sleep 0.5; r2=$(read_cpu)
total1=$(echo "$r1" | awk '{print $1+$2+$3+$4+$5+$6+$7}')
total2=$(echo "$r2" | awk '{print $1+$2+$3+$4+$5+$6+$7}')
idle1=$(echo "$r1" | awk '{print $4}')
idle2=$(echo "$r2" | awk '{print $4}')
awk -v t1="$total1" -v t2="$total2" -v i1="$idle1" -v i2="$idle2" \
  'BEGIN{
    used=((t2-t1)-(i2-i1))*100/(t2-t1)
    printf "  Used : %.1f%%\n  Idle : %.1f%%\n", used, 100-used
  }'

# ── 2. 메모리 사용량 ─────────────────────────────────────
header "Memory Usage"
awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2}
  END{
    u=t-a
    printf "  Total : %.1f MiB\n", t/1024
    printf "  Used  : %.1f MiB (%.1f%%)\n", u/1024, u*100/t
    printf "  Free  : %.1f MiB (%.1f%%)\n", a/1024, a*100/t
  }' /proc/meminfo

# ── 3. 디스크 사용량 ─────────────────────────────────────
header "Disk Usage"
printf "  %-20s %6s %6s %6s %5s\n" "Filesystem" "Size" "Used" "Avail" "Use%"
df -h --output=target,size,used,avail,pcent -x tmpfs -x devtmpfs -x squashfs 2>/dev/null \
  | awk 'NR>1{printf "  %-20s %6s %6s %6s %5s\n",$1,$2,$3,$4,$5}'

# ── 4. CPU 상위 5개 프로세스 ─────────────────────────────
header "Top 5 Processes by CPU"
printf "  %-8s %-6s %-6s %s\n" "PID" "CPU%" "MEM%" "COMMAND"
ps -eo pid,pcpu,pmem,comm --sort=-pcpu 2>/dev/null \
  | awk 'NR>1 && NR<=6{printf "  %-8s %-6s %-6s %s\n",$1,$2,$3,$4}'

# ── 5. 메모리 상위 5개 프로세스 ──────────────────────────
header "Top 5 Processes by Memory"
printf "  %-8s %-6s %-6s %s\n" "PID" "MEM%" "CPU%" "COMMAND"
ps -eo pid,pmem,pcpu,comm --sort=-pmem 2>/dev/null \
  | awk 'NR>1 && NR<=6{printf "  %-8s %-6s %-6s %s\n",$1,$2,$3,$4}'

echo

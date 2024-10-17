#!/usr/bin/env bash

# Usage:
# bash <(curl -Lso- https://cf.j1ang.eu.org/sh/bashrc.sh)

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE="\033[34m"; PURPLE="\033[35m"; BOLD="\033[1m"; NC='\033[0m';

success() { printf "${GREEN}%s${NC} ${@:2}\n" "$1"; }
info() { printf "${BLUE}%s${NC} ${@:2}\n" "$1"; }
danger() { printf "${RED}[x] %s${NC}\n" "$@"; }
warn() { printf "${YELLOW}%s${NC}\n" "$@"; }

# allusers=$( cat /etc/passwd | grep -vE "(/bin/false|/sbin/nologin|/bin/sync|guest-)" | cut -d: -f1 )
# allusers=$(awk -F':' '$2 ~ "\\$" {print $1}' /etc/shadow)

apply_bashrc() {
  for file in /root/.bashrc /home/*/.bashrc; do
    # echo $file;
    if [[ ! -f "$file" ]]; then continue; fi
    # insert lines
    printf "%s\n" "# => vps.dance" >>$file
    printf "%s\n" "$(curl -Lso- https://cf.j1ang.eu.org/sh/raw/VPSDance/scripts/main/files/bashrc)" >>$file
    printf "%s\n" "# <= vps.dance" >>$file
  done
}

restore_bashrc() {
  for file in /root/.bashrc /home/*/.bashrc; do
    # echo $file;
    if [[ ! -f "$file" ]]; then continue; fi
    # delete lines between two patterns
    sed -i '/^# => vps.dance/,/^# <= vps.dance/d' $file
  done
}

reload_bashrc() {
  # source ~/.bashrc
  # fix: source bashrc not working
  exec bash
}

menu() {
  # clear
  info "shell 终端优化, 请选择: "
  local AR=(
    [1]='应用'
    [2]='还原'
  )
  for i in "${!AR[@]}"; do
    success "$i." "${AR[i]}"
  done
  while :; do
    read -p "输入数字以选择: " num
    [[ -n "${AR[num]}" ]] || {
      danger "invalid number"
      continue
    }
    break
  done
  if [[ "$num" == "1" ]]; then
    restore_bashrc
    apply_bashrc
    reload_bashrc
  elif [[ "$num" == "2" ]]; then
    restore_bashrc
    reload_bashrc
  fi
}

menu
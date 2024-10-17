#!/usr/bin/env bash
# bash <(curl -Lso- https://cf.j1ang.eu.org/sh/swap.sh)

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE="\033[34m"; PURPLE="\033[35m"; BOLD="\033[1m"; NC='\033[0m';

success() { printf "${GREEN}%s${NC} ${@:2}\n" "$1"; }
info() { printf "${BLUE}%s${NC} ${@:2}\n" "$1"; }
danger() { printf "${RED}[x] %s${NC}\n" "$@"; }
warn() { printf "${YELLOW}%s${NC}\n" "$@"; }

swap_info() {
  info "当前swap:"
  # free -h
  swapon --show
}
swap_file="/vd_swap"
line_mark="# vd_swap"
create_swap() {
  clear;
  while :; do
    read -p "请输入swap大小 (单位为G): " swap_size
    [[ $swap_size =~ ^[0-9]*\.?[0-9]+$ ]] || {
      echo "invalid number"
      continue
    }
    break
  done
  swap_size=${swap_size:-1}
  info "swap大小为: ${swap_size}G, 正在创建swap..."
  delete_swap
  # dd if=/dev/zero of=$swap_file bs=1G count=$swap_size
  fallocate -l "${swap_size}G" $swap_file
  chmod 600 $swap_file; mkswap $swap_file; swapon $swap_file;
  echo "$swap_file swap swap defaults 0 0" >> /etc/fstab
  echo "vm.swappiness=10 $line_mark" >> /etc/sysctl.conf
  sysctl -p > /dev/null;
  info "swap创建成功!"
  swap_info
}
delete_swap() {
  if [[ ! -f "$swap_file" ]]; then return; fi
  swapoff $swap_file # 已经关闭, 会报错
  rm -f $swap_file
  sed -i "\#${swap_file}#d" /etc/fstab
  sed -i "/${line_mark}/d" /etc/sysctl.conf
}
restore_swap() {
  delete_swap
  sysctl -p > /dev/null;
  info "swap设置还原成功!"
  swap_info
}

menu() {
  info "swap分区 (虚拟内存):"
  local AR=(
    [0]="查看swap"
    [1]="添加swap"
    [2]="还原swap"
  )
  for i in "${!AR[@]}"; do
    success "$i." "${AR[i]}"
  done
  while :; do
    read -p "输入数字以选择: " num
    [[ -n "${AR[num]}" ]] || {
      danger "invalid"
      continue
    }
    break
  done
  main="${AR[num]}"
  if [[ "$num" == "0" ]]; then
    clear
    swap_info
    printf "%-37s\n" "-" | sed 's/\s/-/g'
    menu
  elif [[ "$num" == "1" ]]; then
    create_swap
  elif [[ "$num" == "2" ]]; then
    restore_swap
  fi
}
menu
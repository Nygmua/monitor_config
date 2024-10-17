#!/usr/bin/env bash

# 用法:
# # bash <(curl -Lso- https://cf.j1ang.eu.org/sh/ssh.sh) [key|port|pwd]

# 检测发行版
# DISTRO=$( ([[ -e "/usr/bin/yum" ]] && echo 'CentOS') || ([[ -e "/usr/bin/apt" ]] && echo 'Debian') || echo 'unknown' )
# 颜色定义
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[34m'; CYAN='\033[0;36m'; PURPLE='\033[35m'; BOLD='\033[1m'; NC='\033[0m';

# 打印成功信息
success() { printf "${GREEN}%b${NC} ${@:2}\n" "$1"; }

# 打印信息
info() { printf "${CYAN}%b${NC} ${@:2}\n" "$1"; }

# 打印错误信息
danger() { printf "\n${RED}[x] %b${NC}\n" "$@"; }

# 打印警告信息
warn() { printf "${YELLOW}%b${NC}\n" "$@"; }

# 提示用户输入是或否
promptYn () {
  default=${2:-Y}
  while true; do
    read -p "${1:-"请回答"} ([Y]es, [N]o), 默认 [$default] " yn
    case "${yn:-$default}" in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) clear; echo "请回答 [y] 是 或 [n] 否.";;
    esac
  done
}

# 将输入参数转换为小写
name=$( tr '[:upper:]' '[:lower:]' <<<"$1" )

# 设置SSH公钥认证
ssh_key () {
  # 遍历每个用户的家目录
  for home in /root /home/*;
  do
    if [[ ! -e "$home" ]]; then continue; fi;
    mkdir -p "${home}/.ssh"; chmod 700 "${home}/.ssh";
    if [[ ! -f "${home}/.ssh/authorized_keys" ]]; then echo '' >> "${home}/.ssh/authorized_keys"; fi
    chmod 600 "${home}/.ssh/authorized_keys"
  done
  echo "请粘贴您的SSH公钥 (~/.ssh/id_rsa.pub):"
  IFS= read -d '' -n 1 text
  while IFS= read -d '' -n 1 -t 2 c
  do
    text+=$c
  done
  text=$(echo "$text" | sed '/^$/d')

  # 启用公钥认证
  enable_pubkey
  for home in /root /home/*;
  do
    if [[ ! -e "$home" ]]; then continue; fi;
    echo "$text" >> "${home}/.ssh/authorized_keys"
    # 删除重复的公钥
    sed -i "/^$/d" "${home}/.ssh/authorized_keys"
    sed -i -nr 'G;/^([^\n]+\n)([^\n]+\n)*\1/!{P;h}' "${home}/.ssh/authorized_keys"
  done
  success "[*] SSH公钥已添加."
  warn "\n启用或禁用密码登录:"
  info " bash <(curl -Lso- https://cf.j1ang.eu.org/sh/ssh.sh) pwd\n"
}

# 启用公钥认证
enable_pubkey() {
  sed -i 's/^#\?\(PubkeyAuthentication[[:space:]]\+\).*$/\1yes/' /etc/ssh/sshd_config
  systemctl restart sshd;
}

# 启用密码认证
enable_pwd() {
  sed -i 's/^#\?\(PasswordAuthentication[[:space:]]\+\).*$/\1yes/' /etc/ssh/sshd_config
  systemctl restart sshd;
  success "[*] SSH密码认证已启用."
}

# 禁用密码认证
disable_pwd() {
  sed -i 's/^#\?\(PasswordAuthentication[[:space:]]\+\).*$/\1no/' /etc/ssh/sshd_config
  systemctl restart sshd;
  success "[*] SSH密码认证已禁用."
}

# SSH密码管理
ssh_pwd() {
  local AR=(
    [1]="启用密码认证"
    [2]="禁用密码认证"
    [3]="退出"
  )
  info "启用或禁用密码登录:"
  for i in "${!AR[@]}"; do
    success "$i." "${AR[i]}"
  done
  while :; do
    read -p "请输入一个数字: " num
    [[ $num =~ ^[0-9]+$ ]] || { danger "无效的数字"; continue; }
    break
  done
  case $num in
    1)
      enable_pwd
    ;;
    2)
      disable_pwd
    ;;
    *)
      exit
    ;;
  esac
}

# iptables持久化设置（适用于Debian/Ubuntu）
iptables_persistence() {
cat > /etc/network/if-pre-up.d/iptables << EOF
#!/bin/sh
iptables-restore < /etc/iptables.rules
exit 0
EOF
chmod +x /etc/network/if-pre-up.d/iptables
}

# 设置SSH端口
ssh_port() {
  local port='35653';
  read -p "请输入SSH端口 [默认=$port]: " _p && [ -n "$_p" ] && SSH_PORT=$_p || SSH_PORT=$port;
  sed -i "s/#\?.*\Port\s*.*$/Port $SSH_PORT/" /etc/ssh/sshd_config;
  systemctl restart sshd;
  info "[*] /etc/ssh/sshd_config 已修改."
  if [ -e /etc/sysconfig/firewalld ]; then # CentOS
    if [[ $( firewall-cmd --zone=public --query-port=${SSH_PORT}/tcp ) == 'no' ]]; then
      firewall-cmd --permanent --zone=public --add-port=${SSH_PORT}/tcp
      firewall-cmd --reload
    fi
  elif [ -e /etc/ufw/before.rules ]; then # Debian/Ubuntu
    ufw allow $SSH_PORT/tcp
    ufw reload
  elif [ -e /etc/sysconfig/iptables ]; then # CentOS
    iptables -I INPUT -p tcp --dport $SSH_PORT -j ACCEPT
    service iptables save
    service iptables restart
  elif [ -e /etc/iptables.rules ]; then # Debian/Ubuntu
    iptables -I INPUT -p tcp --dport $SSH_PORT -j ACCEPT
    iptables-save > /etc/iptables.rules
  fi
  local ip=`curl -4Ls ip.sb || curl -6Ls ip.sb || echo 'localhost'`;
  warn "[*] 请勿退出当前ssh, 新开终端测试 \"ssh root@$ip -p $SSH_PORT\" 是否能登录"
  warn "[*] 如不能登录, 重新执行本命令, 改回默认的 22 端口"
}

# 主函数，根据输入参数执行相应的功能
main() {
  case "$name" in
    key)
      ssh_key
    ;;
    port)
      ssh_port
    ;;
    pwd)
      ssh_pwd
    ;;
    *)
      ssh_key
      exit
    ;;
  esac
}

# 执行主函数
main

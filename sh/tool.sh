#!/usr/bin/env bash

# Usage:
# bash <(curl -Lso- https://cf.j1ang.eu.org/sh/tool.sh)

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[34m'; CYAN='\033[0;36m'; PURPLE='\033[35m'; BOLD='\033[1m'; NC='\033[0m';
success() { printf "${GREEN}%b${NC} ${@:2}\n" "$1"; }
info() { printf "${CYAN}%b${NC} ${@:2}\n" "$1"; }
danger() { printf "\n${RED}[x] %b${NC}\n" "$@"; }
warn() { printf "${YELLOW}%b${NC}\n" "$@"; }

OS=$(uname -s) # Linux, FreeBSD, Darwin
ARCH=$(uname -m) # x86_64, arm64, aarch64
DISTRO=$( ([[ -e "/usr/bin/yum" ]] && echo 'CentOS') || ([[ -e "/usr/bin/apt" ]] && echo 'Debian') || echo 'unknown' )
debug=$( [[ $OS == "Darwin" ]] && echo true || echo false )
cnd=$( tr '[:upper:]' '[:lower:]' <<<"$1" )
SH='https://cf.j1ang.eu.org/sh'
GH='http://gh.j1ang.me/'
CONF_PATH="/opt/tool"
raw() {
  RAW='https://raw.githubusercontent.com'
  # if [[ "$cnd" =~ ^(fastgit)$ ]]; then echo "https://raw.fastgit.org"
  if [[ "$cnd" =~ ^(ghproxy)$ ]]; then echo "${GH}/${RAW}"
  elif [[ "${1}" =~ ^(ghproxy)$ ]]; then echo "${GH}/${RAW}"
  elif [[ "${1}" =~ ^(sh)$ ]]; then echo "${SH}/raw"
  else echo $RAW
  fi
}
# echo $(raw 'ghproxy')
# curl -Ls "$(raw '')/VPSDance/scripts/main/ssh.sh"

check_root() {
  if [[ "$USER" != 'root' ]]; then # [[ "$EUID" -ne 0 ]]
    danger "Please run this script as root!"; exit 1;
    # if [[ "$debug" != true ]]; then exit 1; fi
  fi
}
next() { printf "%-37s\n" "-" | sed 's/\s/-/g'; }

# if (ver_lte 3 3.0); then echo 3; else echo 2; fi # ver_lte 2.5.7 3 && echo "yes" || echo "no"
ver_lte() { # <=
  [  "$(printf '%s\n' "$@" | sort -V | head -n 1)" = "$1" ] && return 0 || return 1
}
# if (ver_lt 2.9 3); then echo 2; else echo 3; fi
ver_lt() { # <
  [ "$1" = "$2" ] && return 1 || ver_lte "$1" "$2"
}
python_version() {
  python -V 2>&1 | awk '{print $2}' # | awk -F '.' '{print $1}'
}

header() {
  next
  printf "%s\n" "[目前支持: Ubuntu/Debian, Centos/Redhat]"
  next
}
footer() {
  BLUE="\033[34m"; NC='\033[0m'
  printf "%-37s\n" "-" | sed 's/\s/-/g'
  printf "%b\n" " Supported by: ${BLUE}J1ang${NC}"
  printf "%-37s\n" "-" | sed 's/\s/-/g'
}

install_deps() {
  case "${DISTRO}" in
    Debian*|Ubuntu*)
      apt update -y;
      apt install -y curl wget htop zip unzip xz-utils gzip ca-certificates lsof gdu; # zip unzip xz-utils gzip
      # ifconfig/netstat dig/nslookup ping/traceroute telnet/tcpdump nc
      apt install -y net-tools dnsutils iputils-ping mtr traceroute telnet tcpdump netcat-openbsd lsof; 
      apt install -y nmap; # nping
      apt install -y python3 python3-pip;
    ;;
    CentOS*|RedHat*)
      yum update -y;
      yum install -y epel-release which openssl curl wget htop zip unzip xz gzip ca-certificates;
      yum install -y net-tools bind-utils iputils mtr traceroute telnet tcpdump nc;
      yum install -y nmap;
      yum install -y python3 python3-pip;
    ;;
  esac
}
install_bbr() {
  info "bash <(curl -Lso- "$(raw '')/teddysun/across/master/bbr.sh")"
  bash <(curl -Lso- $(raw 'sh')/teddysun/across/master/bbr.sh)
}
ssh_key() { bash <(curl -Lso- ${SH}/ssh.sh); }
bashrc() { bash <(curl -Lso- ${SH}/bashrc.sh); }
tuning() { bash <(curl -Lso- ${SH}/tuning.sh); }
ssh_port() { bash <(curl -Lso- ${SH}/ssh.sh) port; }
add_swap() { bash <(curl -Lso- ${SH}/swap.sh); }
233boy() { bash <(wget -qO- -o- ${GH}https://github.com/233boy/sing-box/raw/main/install.sh); }
ip46() { bash <(curl -Lso- ${SH}/ip46.sh); }
install_tool() {
  bash <(curl -Lso- ${SH}/toolbox.sh) "$@"
}
install_xray() {
  bash <(curl -fsSL $(raw 'sh')/XTLS/Xray-install/main/install-release.sh) install
  # 使用增强版的 geosite/geoip 规则
  wget -O /usr/local/share/xray/geoip.dat ${GH}/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
  wget -O /usr/local/share/xray/geosite.dat ${GH}/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
  info "configuration file: /usr/local/etc/xray/config.json"
  info "status: systemctl status xray"
  info "restart: systemctl restart xray"
}
install_wrap() { bash <(curl -fsSL $(raw 'ghproxy')/P3TERX/warp.sh/main/warp.sh) menu; }
install_wireguard(){
  curl -Ls $(raw 'ghproxy')/teddysun/across/master/wireguard.sh | bash -s -- -r
  # uninstall_wireguard
  # curl -Ls $(raw 'ghproxy')/teddysun/across/master/wireguard.sh | bash -s -- -n
}
unlock_test() {
  info "bash <(curl -Lso- "$(raw '')/lmc999/RegionRestrictionCheck/main/check.sh")"
  bash <(curl -Lso- ${SH}/unlockTest.sh)
}
tiktok_test() {
  info "bash <(curl -Lso- "$(raw '')/lmc999/TikTokCheck/main/tiktok.sh")"
  bash <(curl -Lso- "$(raw 'sh')/lmc999/TikTokCheck/main/tiktok.sh")
}
openai_test() {
  info "bash <(curl -Lso- "$(raw '')/missuo/OpenAI-Checker/main/openai.sh")"
  bash <(curl -Lso- "$(raw 'sh')/missuo/OpenAI-Checker/main/openai.sh")
}
bench() { bash <(curl -Lso- ${SH}/bench.sh); }
# speedtest() { bash <(curl -Lso- ${SH}/speedtest.sh); }
# https://github.com/veoco/bim-core/
# hyperspeed() { bash <(curl -Lso- https://bench.im/hyperspeed); }
iabc_speedtest() { bash <(curl -sL https://jihulab.com/i-abc/Speedtest/-/raw/main/speedtest.sh); }
# lemon_bench() { curl -fsSL http://ilemonra.in/LemonBenchIntl | bash -s fast; }
yabs() {
  while :; do
    read -p "输入Geekbench 版本 [默认=6, 可选:4/5/6]: " BENCH_VER
    BENCH_VER=${BENCH_VER:-6}
    [[ $BENCH_VER =~ ^[0-9]+$ ]] || {
      echo "invalid number"
      continue
    }
    break
  done
  local cmd="curl -sL yabs.sh | bash -s -- -$BENCH_VER"
  local AR=(
    [1]='仅Benchmark'
    [2]='仅fio'
    [3]='仅iperf'
    [4]='Benchmark+fio+iperf'
  )
  clear;
  info "Geekbench 版本 $BENCH_VER, 请选择测试目标: "
  for i in "${!AR[@]}"; do
    success "$i." "${AR[i]}"
  done
  while :; do
    read -p "输入数字以选择: " snum
    [[ -n "${AR[snum]}" ]] || {
      danger "invalid"
      continue
    }
    break
  done
  if [[ "$snum" == "1" ]]; then cmd="$cmd -din"
  elif [[ "$snum" == "2" ]]; then cmd="$cmd  -ign" $log
  elif [[ "$snum" == "3" ]]; then cmd="$cmd  -dgn" $log
  elif [[ "$snum" == "4" ]]; then cmd="$cmd  -n" $log
  fi
  clear;
  info "$cmd";
  eval "$cmd";
}
besttrace() { bash <(curl -Lso- ${SH}/autoBestTrace.sh); }
nexttrace() { bash <(curl -Lso- ${SH}/autoNexttrace.sh); }
unix_bench() { bash <(curl -Lso- $(raw 'ghproxy')/teddysun/across/master/unixbench.sh); }
reinstall() { bash <(curl -Lso- $(raw 'ghproxy')/hiCasper/Shell/master/AutoReinstall.sh); }
uninstall() {
  app="$@"
  if [[ "$app" == "hy2" ]]; then
    app="hysteria-server"
  fi
  un_service() { systemctl disable $app --now; rm -rf "/etc/systemd/system/$app.service"; }
  case "$app" in
    xray)
      un_service;
      rm -rf /etc/systemd/system/xray@.service /usr/local/bin/xray
      rm -rf /usr/local/etc/xray/ /usr/local/share/xray/ /var/log/xray/
    ;;
    ss)
      un_service;
      rm -rf $CONF_PATH/ss.json /usr/bin/ssserver /usr/bin/sslocal /usr/bin/ssurl /usr/bin/ssmanager /usr/bin/ssservice
    ;;
    snell)
      un_service;
      rm -rf $CONF_PATH/snell.conf /usr/bin/snell-server
    ;;
    realm)
      un_service;
      rm -rf $CONF_PATH/realm.toml /usr/bin/realm
    ;;
    gost)
      un_service;
      rm -rf $CONF_PATH/gost.json /usr/bin/gost
    ;;
    hysteria-server)
      un_service;
      rm -rf /etc/hysteria/ /usr/local/bin/hysteria
    ;;
    nali)
      rm -rf ~/.config/nali ~/.local/share/nali /usr/bin/nali
    ;;
    ddns-go)
      un_service;
      rm -rf $CONF_PATH/ddns-go.yaml /usr/bin/ddns-go
    ;;
   *)
    echo "$@"; exit;
   ;;
  esac
  echo -e "\n${GREEN}Done${NC}" 
}

menu() {
  header
  info "请选择要使用的功能"
  local AR=(
    [1]="[推荐] 配置SSH Public Key (SSH免密登录)"
    [2]="[推荐] 终端优化 (颜色美化/上下键查找历史)"
    [3]="[推荐] 安装并开启 BBR"
    [4]="[推荐] 安装常用软件 (ping/traceroute/nslookup/nping/nc/tcpdump/python3/gdu)"
    [5]="[推荐] 系统优化 (TCP网络优化/资源限制优化)"
    [6]="[推荐] 修改默认SSH Port端口 (减少被扫描风险)"
    [7]="增加swap分区 (虚拟内存)"
    [8]="IPv4/IPv6优先级调整; 启用/禁用IPv6"
    [10]="安装/卸载 xray"
    [11]="安装/卸载 shadowsocks"
    [12]="安装/卸载 snell"
    [13]="安装/卸载 hysteria 2"
    [14]="安装/卸载 realm (端口转发工具)"
    [15]="安装/卸载 gost (隧道/端口转发工具)"
    [16]="安装/卸载 nali (IP查询工具)"
    [17]="安装/卸载 ddns-go (DDNS工具)"
    [18]="安装 233boy (一键singbox)"
    # [17]="安装 warp"
    # [18]="安装 wireguard"
    [21]="检测 VPS流媒体解锁 (RegionRestrictionCheck)"
    [22]="检测 VPS信息/IO/网速 (Bench.sh)"
    # [23]="检测 VPS到国内网速"
    # [23]="检测 VPS到国内网速 (Superspeed)"
    # [23]="检测 VPS到国内网速 (HyperSpeed)"
    [23]="检测 单线程/多线程网速 (i-abc/Speedtest)"
    [24]="性能/IO 测试 (YABS)"
    # [25]="检测 VPS信息/IO/路由 (LemonBench)"
    [25]="检测 回程路由 (BestTrace)"
    [26]="检测 回程路由 (NextTrace)"
    [27]="检测 Tiktok解锁 (TikTokCheck)"
    [28]="检测 ChatGPT解锁 (OpenAI-Checker)"
    [29]="DD 重装系统"
    # [29]="性能测试 (UnixBench)"
    # [31]="DD重装Linux系统"
    # [100]=""
  )
  for i in "${!AR[@]}"; do
    success "$i." "${AR[i]}"
  done

  while :; do
    read -p "输入数字以选择:" num
    [[ $num =~ ^[0-9]+$ ]] || { danger "请输入正确的数字"; continue; }
    break
  done
  main="${AR[num]}"
  installs=(10 11 12 13 14 15 16 17)
  if [[ " ${installs[@]} " =~ " ${num} " ]]; then
    install_menu
  fi
}
install_menu() {
  # clear
  info "$main, 请选择: "
  local AR=(
    [0]='返回'
    [1]='安装'
    [2]='卸载'
  )
  for i in "${!AR[@]}"; do
    success "$i." "${AR[i]}"
  done
  while :; do
    read -p "输入数字以选择: " inum
    [[ -n "${AR[inum]}" ]] || { danger "invalid number"; continue; }
    break
  done
  if [[ "$inum" == "0" ]]; then
    clear; menu;
  fi
}

main() {
  clear
  # header
  if [[ "$num" == "1" ]]; then ssh_key
  elif [[ "$num" == "2" ]]; then bashrc
  elif [[ "$num" == "3" ]]; then install_bbr
  elif [[ "$num" == "4" ]]; then install_deps
  elif [[ "$num" == "5" ]]; then tuning
  elif [[ "$num" == "6" ]]; then ssh_port
  elif [[ "$num" == "7" ]]; then add_swap
  elif [[ "$num" == "8" ]]; then ip46
  elif [[ "$num" == "10" ]]; then 
    [[ "$inum" == "1" ]] && install_xray || uninstall "xray";
  elif [[ "$num" == "11" ]]; then
    [[ "$inum" == "1" ]] && install_tool "ss" || uninstall "ss";
  elif [[ "$num" == "12" ]]; then
    [[ "$inum" == "1" ]] && install_tool "snell" || uninstall "snell";
  elif [[ "$num" == "13" ]]; then
    [[ "$inum" == "1" ]] && install_tool "hy2" || uninstall "hy2";
  elif [[ "$num" == "14" ]]; then
    [[ "$inum" == "1" ]] && install_tool "realm" || uninstall "realm";
  elif [[ "$num" == "15" ]]; then
    [[ "$inum" == "1" ]] && install_tool "gost" || uninstall "gost";
  elif [[ "$num" == "16" ]]; then
    [[ "$inum" == "1" ]] && install_tool "nali" || uninstall "nali";
  elif [[ "$num" == "17" ]]; then
    [[ "$inum" == "1" ]] && install_tool "ddns-go" || uninstall "ddns-go";
  elif [[ "$num" == "18" ]]; then 233boy
  # elif [[ "$num" == "17" ]]; then install_wrap
  # elif [[ "$num" == "18" ]]; then install_wireguard
  elif [[ "$num" == "21" ]]; then unlock_test
  elif [[ "$num" == "22" ]]; then bench
  elif [[ "$num" == "23" ]]; then iabc_speedtest
  elif [[ "$num" == "24" ]]; then yabs
  elif [[ "$num" == "25" ]]; then besttrace
  elif [[ "$num" == "26" ]]; then nexttrace
  elif [[ "$num" == "27" ]]; then tiktok_test
  elif [[ "$num" == "28" ]]; then openai_test
  elif [[ "$num" == "29" ]]; then reinstall
  # elif [[ "$num" == "29" ]]; then unix_bench
  # elif [[ "$num" == "31" ]]; then reinstall
  else exit
  fi
}

check_root
menu
main
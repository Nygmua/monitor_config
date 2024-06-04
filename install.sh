#!/bin/bash

# 设置域名
domain=""

# 设置docker-compose.yml文件路径
compose_file="docker-compose.yml"

# 设置docker-compose-exporter.yml文件路径
compose_exporter_file="docker-compose-exporter.yml"

# 设置docker-compose-nezha.yml文件路径
compose_nezha_file="docker-compose-nezha.yml"

sshPort=22

# 检查Docker是否安装函数
checkDockerInstalled() {
  # 检查Docker是否已安装
  if ! command -v docker &>/dev/null; then
    echo "Docker未安装，开始安装Docker..."
    curl -fsSL https://get.docker.com | bash -s docker

    # 检查Docker安装是否成功
    if [ $? -ne 0 ]; then
      echo "Docker安装失败，请检查网络连接或URL是否正确。"
      exit 1
    fi
    echo "Docker安装成功。"
  else
    echo "Docker已安装，跳过安装步骤。"
  fi
}

# 下载docker-compose.yml(5个全)函数
wgetDockerCompose() {
  # 下载docker-compose.yml文件
  echo "下载docker-compose.yml文件..."
  wget https://raw.githubusercontent.com/Sm1rkBoy/monitor_config/main/docker-compose.yml -O docker-compose.yml

  # 检查下载是否成功
  if [ $? -ne 0 ]; then
    echo "下载docker-compose.yml文件失败，请检查网络连接或URL是否正确。"
    exit 1
  fi
}

# 替换主机名函数
changeHostname() {
  read -p "请输入主机名: " hostname
  sed -i "s|hostname: .*|hostname: ${hostname}|" $compose_file
}

# 替换Username函数
changeUsername() {
  read -p "请输入Grafana账号: " username
  # 替换Grafana账号
  sed -i "s/GF_SECURITY_ADMIN_USER=.*/GF_SECURITY_ADMIN_USER=${username}/" $compose_file
}

# 替换Grafana密码
changePassowrd() {
  read -sp "请输入Grafana密码: " password
  echo
  # 替换Grafana密码
  sed -i "s/GF_SECURITY_ADMIN_PASSWORD=.*/GF_SECURITY_ADMIN_PASSWORD=${password}/" $compose_file
}

# 输入的域名导出成全局变量
globalDomain() {
  read -p "请输入访问域名: " domain
  export domain
}

# 创建Prometheus配置文件函数
touchPrometheusConfig() {
  # 创建Prometheus配置文件目录
  mkdir -p prometheus

  # 创建Prometheus配置文件
  touch prometheus/prometheus.yml
  echo "Prometheus配置文件已创建。"
}

# 检查common网络是否存在
checkNetworkInstalled() {
  # 检查名为common的网络是否存在
  network_exists=$(docker network ls --filter name=^common$ --format "{{.Name}}")

  if [ -z "$network_exists" ]; then
    echo "创建名为common的Docker网络..."
    docker network create common

    # 检查网络创建是否成功
    if [ $? -ne 0 ]; then
      echo "创建Docker网络失败。"
      exit 1
    fi

    echo "Docker网络common已创建。"
  else
    echo "Docker网络common已存在，不需要创建。"
  fi
}

# 下载nginx的grafana反代文件函数
wgetProxyGrafanaConfig() {
  # 下载nginx的grafana反代文件
  echo "下载nginx的grafana反代文件..."
  wget https://raw.githubusercontent.com/Sm1rkBoy/monitor_config/main/nginx/grafana.conf -O grafana.conf
  mv grafana.conf /var/lib/docker/volumes/root_nginx/_data/conf.d/grafana.conf
  echo "grafana反代配置文件已成功下载"
}

# nginx配置grafana反代
setProxyGrafanaConf() {
  # 配置Nginx
  nginx_conf="/var/lib/docker/volumes/root_nginx/_data/conf.d/default.conf"

  if [ -f "$nginx_conf" ]; then
    echo "删除Nginx默认配置文件..."
    rm "$nginx_conf"
  fi

  echo "创建Grafana Nginx反代配置文件..."
  wgetProxyGrafanaConfig

  # 确定配置文件路径
  config_file="/var/lib/docker/volumes/root_nginx/_data/conf.d/grafana.conf"

  # 检查配置文件是否存在
  if [ -f "$config_file" ]; then
    sed -i "s/server_name \[填入你设置的域名\];/server_name ${domain};/" $config_file
    echo "域名已更新为：$domain"
    echo "Grafana反代文件已创建。"
  else
    echo "错误：grafana.conf文件未找到。"
    return 1
  fi

  # 重启Nginx
  echo "重启Nginx..."
  if docker restart nginx; then
    echo "Nginx重启成功。"
  else
    echo "错误：Nginx重启失败。"
    return 1
  fi

  echo "配置完成。"

}

# 1.开始docker-compose.yml(5合1)安装函数
dockerComposeFullInstall() {
  # 检查Docker是否安装
  checkDockerInstalled
  # 下载文件
  wgetDockerCompose
  # 更改hostname主机名
  changeHostname
  # 更改用户名
  changeUsername
  # 更改密码
  changePassowrd
  # 域名导出成全局变量
  globalDomain
  echo "主机名、Grafana账号、密码已成功替换到docker-compose.yml文件中。"
  echo "域名将会待服务器启动完成之后写入反代文件中!"
  # 创建数据库配置文件
  touchPrometheusConfig
  # 检查网络是否安装
  checkNetworkInstalled

  # 启动服务
  echo "启动服务..."
  docker compose up -d

  # 设置Nginx代理Grafana
  setProxyGrafanaConf

  # 检查服务是否启动成功
  if [ $? -ne 0 ]; then
    echo "服务启动失败。"
    exit 1
  fi
  echo "服务已成功启动。"
}

# 2.卸载docker-compose.yml(5合1)函数
dockerComposeUninstallAll() {
  echo "正在卸载所有容器..."
  docker compose down --volumes
  echo "正在移除Docker网络common..."
  docker network remove common
  echo "正在清理Docker系统..."
  docker system prune -a
  echo "正在删除docker-compose.yml文件..."
  rm docker-compose.yml
  echo "删除prometheus.yml"
  rm -rf prometheus
  echo "卸载完成。"
}

# 下载docker-compose-exporter.yml函数
wgetDockerComposeExporter() {
  # 下载docker-compose-exporter.yml文件
  echo "下载docker-compose-exporter.yml文件..."
  wget https://raw.githubusercontent.com/Sm1rkBoy/monitor_config/main/docker-compose-exporter.yml -O docker-compose-exporter.yml

  # 检查下载是否成功
  if [ $? -ne 0 ]; then
    echo "下载docker-compose-exporter.yml文件失败，请检查网络连接或URL是否正确。"
    exit 1
  fi
}

# 替换exporter主机名函数
changeExporterHostname() {
  read -p "请输入主机名: " hostname
  sed -i "s|hostname: .*|hostname: ${hostname}|" $compose_exporter_file
}

# 3.启动exporters函数
exportersInstall() {
  checkDockerInstalled
  wgetDockerComposeExporter
  changeExporterHostname
  # 启动fping-exporter和node-exporter服务
  docker compose -f docker-compose-exporter.yml up -d

  echo "fping-exporter和node-exporter服务已成功启动,并启用自动更新。"
}

# 4.卸载exporters函数
dockerComposeUninstallExporter() {
  echo "正在卸载Exporter容器..."
  docker compose -f docker-compose-exporter.yml down --volumes
  echo "正在清理Docker系统..."
  docker system prune -a
  echo "正在删除docker-compose-exporter.yml文件..."
  rm docker-compose-exporter.yml
  echo "卸载完成。"
}

# 下载docker-compose-nezha.yml函数
wgetDockerComposeNezha() {
  # 下载docker-compose-nezha.yml文件
  echo "下载docker-compose-nezha.yml文件..."
  wget https://raw.githubusercontent.com/Sm1rkBoy/monitor_config/main/nezha/docker-compose-nezha.yml -O docker-compose-nezha.yml

  # 检查下载是否成功
  if [ $? -ne 0 ]; then
    echo "下载docker-compose-nezha.yml文件失败，请检查网络连接或URL是否正确。"
    exit 1
  fi
}

setNezhaConfig() {
  mkdir -p nezha
  read -p "面板访问的域名或ip: " domain
  read -p "请输入未被DNS接管的域名或者ip: " nezhaCommDomain
  read -p "请输入GitHub ID (Oauth2.Admin): " github_id
  read -p "请输入Client ID (Oauth2.ClientID): " client_id
  read -p "请输入Client Secret (Oauth2.ClientSecret): " client_secret

  wget -O ./nezha/config.yaml https://raw.githubusercontent.com/Sm1rkBoy/monitor_config/main/nezha/config.yaml

  # 替换config.yaml中的内容
  sed -i "s/GRPCHost: .*/GRPCHost: ${nezhaCommDomain}/" ./nezha/config.yaml
  sed -i "s/Admin: .*/Admin: ${github_id}/" ./nezha/config.yaml
  sed -i "s/ClientID: .*/ClientID: ${client_id}/" ./nezha/config.yaml
  sed -i "s/ClientSecret: .*/ClientSecret: ${client_secret}/" ./nezha/config.yaml
  echo "Nezha配置文件已创建并更新。"
  export domain
}

# 开始docker-compose-nezha.yml安装函数
dockerComposeNezhaInstall() {
  # 启动服务
  echo "正在启动哪吒探针..."
  docker compose -f docker-compose-nezha.yml up -d
  # 检查服务是否启动成功
  if [ $? -ne 0 ]; then
    echo "服务启动失败。"
    exit 1
  fi
  echo "服务已成功启动。"
}

# 下载nginx的nezha反代文件函数
wgetProxyNezhaConfig() {
  # 下载nginx的nezha反代文件
  echo "下载nginx的nezha反代文件..."
  wget https://raw.githubusercontent.com/Sm1rkBoy/monitor_config/main/nginx/nezha.conf -O nezha.conf
  mv nezha.conf /var/lib/docker/volumes/root_nginx/_data/conf.d/nezha.conf
  echo "哪吒反代配置文件已成功下载"
}

# nginx配置nezha反代
setProxyNezhaConf() {
  # 配置Nginx
  nginx_conf="/var/lib/docker/volumes/root_nginx/_data/conf.d/default.conf"

  if [ -f "$nginx_conf" ]; then
    echo "删除Nginx默认配置文件..."
    rm "$nginx_conf"
  fi

  echo "创建nezha.conf配置文件..."
  wgetProxyNezhaConfig
  # 确定配置文件路径
  config_file="/var/lib/docker/volumes/root_nginx/_data/conf.d/nezha.conf"

  # 检查配置文件是否存在
  if [ -f "$config_file" ]; then
    sed -i "s/server_name \[填入你设置的域名\];/server_name ${domain};/" $config_file
    echo "域名已更新为：$domain"
    echo "nezha.conf反代文件已创建。"
  else
    echo "错误：nezha.conf文件未找到。"
    return 1
  fi

  # 重启Nginx
  echo "重启Nginx..."
  if docker restart nginx; then
    echo "Nginx重启成功。"
  else
    echo "错误：Nginx重启失败。"
    return 1
  fi

  echo "配置完成。"
}

# 5.nezha安装函数
installNezha() {
  checkDockerInstalled
  wgetDockerComposeNezha
  checkNetworkInstalled
  setNezhaConfig
  dockerComposeNezhaInstall
  setProxyNezhaConf
}

# 6.卸载nezha函数
uninstallNezha() {
  echo "正在卸载哪吒面板及相关容器..."
  docker compose -f docker-compose-nezha.yml down --volumes
  echo "正在移除Docker网络common..."
  docker network remove common
  echo "正在清理Docker系统..."
  docker system prune -a
  echo "正在删除docker-compose-nezha.yml文件..."
  rm docker-compose-nezha.yml
  echo "删除哪吒配置文件夹"
  rm -rf nezha
  echo "卸载完成。"
}

# 输入公钥
recordPublicKey() {
  read -p "请输入您的公钥: " publicKey

  if [ -z "$publicKey" ]; then
    echo "没有输入公钥, 退出~"
    return 1
  fi
  export publicKey
}

# 输入ssh端口
recordSshPort() {
  read -p "请输入要修改的ssh端口(按回车使用默认22端口): " inputSshPort

  if [ -n "$inputSshPort" ]; then
    sshPort=$inputSshPort
  fi
  export sshPort
}

# 添加公钥到authorizedKeysFile并修改ssh
setSSHconfig() {
  recordPublicKey
  if [ $? -ne 0 ]; then
    echo "公钥输入错误，退出"
    return 1
  fi

  recordSshPort

  authorizedKeysFile="$HOME/.ssh/authorized_keys"
  sshdConfigFile="/etc/ssh/sshd_config"

  # 确保 .ssh 目录存在
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  # 将公钥添加到 authorized_keys
  if ! grep -qF "$publicKey" "$authorizedKeysFile"; then
    echo "$publicKey" >>"$authorizedKeysFile"
    chmod 600 "$authorizedKeysFile"
    echo "公钥已添加到 $authorizedKeysFile"
  else
    echo "公钥已经存在于 $authorizedKeysFile"
  fi

  # 修改sshd_config
  updateSshdConfig() {
    local param="$1"
    local value="$2"

    if grep -q "^#\?\s*$param" "$sshdConfigFile"; then
      sudo sed -i "s|^#\?\s*$param.*|$param $value|" "$sshdConfigFile"
    else
      echo "$param $value" | sudo tee -a "$sshdConfigFile" >/dev/null
    fi
  }

  # 设置 sshd_config 选项
  updateSshdConfig "Port" "$sshPort"
  updateSshdConfig "PermitRootLogin" "yes"
  updateSshdConfig "PasswordAuthentication" "no"
  updateSshdConfig "PubkeyAuthentication" "yes"
  updateSshdConfig "ChallengeResponseAuthentication" "no"
  updateSshdConfig "UsePAM" "yes"

  # 重启 sshd 服务以应用更改
  if systemctl is-active --quiet sshd; then
    sudo systemctl restart sshd
    echo "sshd 服务已重启,端口为:$sshPort"
  else
    sudo service sshd restart
    echo "sshd 服务已重启,端口为:$sshPort"
  fi
}

# 主函数
echo "欢迎使用Sm1rkBoy's 一键脚本。"
echo "请选择操作："
echo "  1) 面板+数据库+exporter全部安装"
echo "  2) 卸载所有容器并删除镜像"
echo "  ------------------------"
echo "  3) 单独安装exporter端"
echo "  4) 卸载exporter容器并删除镜像"
echo "  ------------------------"
echo "  5) 安装Nezha面板"
echo "  6) 卸载Nezha面板"
echo "  ------------------------"
echo "  7) 修改SSH设置"
echo "  0) 退出"
read -p "请选择操作 [0-7]: " choice

case $choice in
1) dockerComposeFullInstall ;;
2) dockerComposeUninstallAll ;;
3) exportersInstall ;;
4) dockerComposeUninstallExporter ;;
5) installNezha ;;
6) uninstallNezha ;;
7) setSSHconfig ;;
0)
  echo "退出。"
  exit 0
  ;;
*)
  echo "错误"
  exit 1
  ;; # 在默认情况下添加退出语句
esac

#!/bin/bash

# 设置目录和文件路径
INSTALL_DIR="/opt/als"
ALS_BINARY="${INSTALL_DIR}/als-linux-amd64"
LOG_FILE="${INSTALL_DIR}/als-linux-amd64.log"
ALS_URL="https://github.com/wikihost-opensource/als/releases/download/v2.0-fix2/als-linux-amd64"

# 创建安装目录（如果不存在）
if [ ! -d "$INSTALL_DIR" ]; then
  echo "Creating directory: $INSTALL_DIR"
  sudo mkdir -p "$INSTALL_DIR"
fi

# 检查是否已下载 als-linux-amd64
if [ ! -f "$ALS_BINARY" ]; then
  echo "als-linux-amd64 not found. Downloading..."
  sudo curl -L "$ALS_URL" -o "$ALS_BINARY"
  sudo chmod +x "$ALS_BINARY"
  echo "Downloaded and set executable permission for $ALS_BINARY"
else
  echo "als-linux-amd64 already exists at $ALS_BINARY"
fi

# 检查并安装 curl
if ! command -v curl &> /dev/null; then
  echo "curl not found. Installing..."
  sudo apt-get update && sudo apt-get install -y curl
else
  echo "curl is already installed."
fi

# 检查并安装 nxtrace
if ! command -v nxtrace &> /dev/null; then
  echo "nxtrace not found. Installing..."
  curl -s nxtrace.org/nt | bash
else
  echo "nxtrace is already installed."
fi


# 检查 speedtest iperf3 mtr 是否已安装
if ! command -v speedtest &> /dev/null; then
  echo "speedtest not found. Installing..."
  curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
  sudo apt-get update && sudo apt-get install -y speedtest mtr iperf3
else
  echo "speedtest is already installed."
fi


# 要求用户输入 HTTP_PORT
read -p "Please enter the value for HTTP_PORT: " HTTP_PORT

# 检查是否输入了值
if [[ -z "$HTTP_PORT" ]]; then
  echo "Error: HTTP_PORT must be provided. Exiting."
  exit 1
fi

# 设置环境变量
export HTTP_PORT
echo "HTTP_PORT is set to $HTTP_PORT"

# 确保日志文件存在
if [ ! -f "$LOG_FILE" ]; then
  sudo touch "$LOG_FILE"
  sudo chmod 666 "$LOG_FILE"
fi

# 以后台模式启动程序并将日志输出重定向
echo "Starting $ALS_BINARY in the background..."
nohup "$ALS_BINARY" >> "$LOG_FILE" 2>&1 &

# 输出后台进程ID
ALS_PID=$!
echo "$ALS_BINARY is running in the background with PID: $ALS_PID"
echo "Logs are being written to $LOG_FILE"

# 提示用户查看日志的方法
echo "You can view the logs using: tail -f $LOG_FILE"
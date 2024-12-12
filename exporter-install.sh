#!/bin/bash

# 获取用户输入的 fping-exporter 端口号
read -p "请输入 fping-exporter 的监听端口号 (默认为 9605): " fping_port
fping_port=${fping_port:-9605}

# 获取用户输入的 prometheus-node-exporter 端口号
read -p "请输入 prometheus-node-exporter 的监听端口号 (默认为 9100): " node_exporter_port
node_exporter_port=${node_exporter_port:-9100}

# 创建目录并下载文件
mkdir -p /opt/fping
curl -o /opt/fping/fping-exporter https://raw.githubusercontent.com/Nygmua/monitor_config/main/fping-exporter

# 设置权限
chmod +x /opt/fping/fping-exporter

# 安装 fping
apt update && apt install prometheus-node-exporter fping -y

# 添加 fping-exporter 启动任务
cat <<EOF > /etc/systemd/system/fping-exporter.service
[Unit]
Description=Fping Exporter

[Service]
ExecStart=/opt/fping/fping-exporter --fping=/usr/bin/fping -l 0.0.0.0:$fping_port
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 修改 prometheus-node-exporter 的监听端口
if grep -q "ARGS=" /etc/default/prometheus-node-exporter; then
    sed -i "s#ARGS=.*#ARGS=--web.listen-address=\":$node_exporter_port\"#" /etc/default/prometheus-node-exporter
else
    echo "ARGS=--web.listen-address=\":$node_exporter_port\"" >> /etc/default/prometheus-node-exporter
fi

# 重新加载 systemd 并设置开机启动
systemctl daemon-reload
systemctl enable fping-exporter.service
systemctl start fping-exporter.service
systemctl status fping-exporter.service
systemctl status prometheus-node-exporter.service

#!/bin/bash

# 创建目录并下载文件
mkdir -p /opt/fping
curl -o /opt/fping/fping-exporter https://raw.githubusercontent.com/Nygmua/monitor_config/main/fping-exporter

# 设置权限
chmod +x /opt/fping/fping-exporter

# 安装 fping
apt update && apt install prometheus-node-exporter fping -y
# 添加启动任务
cat <<EOF > /etc/systemd/system/fping-exporter.service
[Unit]
Description=Fping Exporter

[Service]
ExecStart=/opt/fping/fping-exporter --fping=/usr/bin/fping -l 0.0.0.0:9605
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并设置开机启动
systemctl daemon-reload
systemctl enable fping-exporter.service
systemctl start fping-exporter.service
systemctl status fping-exporter.service
systemctl status prometheus-node-exporter.service

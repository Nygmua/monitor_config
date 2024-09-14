#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <repository> <filename>"
    echo "Example: $0 nxtrace/nali nali-nt_linux_amd64"
    exit 1
fi

# 获取参数
REPO=$1
FILENAME=$2

# 获取最新的版本号
LATEST_VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep -oP '"tag_name": "\K(.*)(?=")')

if [ -z "$LATEST_VERSION" ]; then
    echo "Error: Could not fetch the latest version."
    exit 1
fi

# 构造下载链接
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$LATEST_VERSION/$FILENAME"

# 下载文件
curl -L -o "$FILENAME" "$DOWNLOAD_URL"

if [ $? -eq 0 ]; then
    echo "Downloaded $FILENAME $LATEST_VERSION successfully."
else
    echo "Error downloading $FILENAME."
fi



#!/bin/bash

# 默认值
DEFAULT_PORT=11086
DEFAULT_PSK="100a6d37-3dd3-bd42-6235-79961247ea9a"

# 解析命令行参数
PORT=${1:-$DEFAULT_PORT}
PSK=${2:-$DEFAULT_PSK}

# 帮助信息
usage() {
    echo "Usage: $0 [PORT] [PSK]"
    echo "  PORT: Listening port (default: $DEFAULT_PORT)"
    echo "  PSK:  Pre-shared key (default: $DEFAULT_PSK)"
    exit 1
}

# 参数验证
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

# 端口号验证
if [[ ! "$PORT" =~ ^[0-9]+$ || "$PORT" -lt 1 || "$PORT" -gt 65535 ]]; then
    echo "Error: Port must be a number between 1 and 65535"
    exit 1
}

# 确保脚本以root权限运行
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# 更新软件包列表并安装必要的工具
apt update
apt install unzip wget -y

# 下载Snell服务器
wget https://dl.nssurge.com/snell/snell-server-v4.1.1-linux-amd64.zip

# 创建安装目录
mkdir -p /usr/local/bin

# 解压文件到指定目录
unzip -o snell-server-v4.1.1-linux-amd64.zip -d /usr/local/bin/

# 赋予可执行权限
chmod +x /usr/local/bin/snell-server

# 创建Snell配置目录
mkdir -p /etc/snell

# 创建Snell配置文件
cat > /etc/snell/snell-server.conf << EOL
[snell-server]
listen = 0.0.0.0:$PORT
psk = $PSK
ipv6 = false
EOL

# 创建Systemd服务文件
cat > /lib/systemd/system/snell.service << EOL
[Unit]
Description=Snell Proxy Service
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
LimitNOFILE=32768
ExecStart=/usr/local/bin/snell-server -c /etc/snell/snell-server.conf
AmbientCapabilities=CAP_NET_BIND_SERVICE
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=snell-server

[Install]
WantedBy=multi-user.target
EOL

# 重新加载systemd服务
systemctl daemon-reload

# 启用开机自启
systemctl enable snell

# 启动服务
systemctl start snell

# 清理下载的压缩文件
rm snell-server-v4.1.1-linux-amd64.zip

# 检查服务状态
systemctl status snell

echo "Snell服务器安装完成"
echo "端口: $PORT"
echo "PSK: $PSK"

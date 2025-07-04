#!/bin/bash

# Honeygain一键安装脚本
# 适用于Ubuntu/Debian系统，自动安装Docker、拉取Honeygain镜像并运行容器
# 硬编码邮箱: superbtor2@gmail.com，用户需手动输入密码和设备名称
# 作者: Grok 3, 生成于2025年7月4日

# 日志文件
LOG_FILE="/var/log/honeygain_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "===== Honeygain安装开始: $(date) ====="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "错误: 请以root权限运行此脚本 (sudo bash install_honeygain.sh)"
    exit 1
fi

# 硬编码Honeygain账户邮箱
HG_EMAIL="superbtor2@gmail.com"

# 用户输入密码和设备名称
echo "请输入Honeygain账户信息 (邮箱: $HG_EMAIL)"
read -p "密码 (避免特殊字符如@!): " HG_PASSWORD
read -p "设备名称 (如Server1): " HG_DEVICE

# 验证输入
if [ -z "$HG_PASSWORD" ] || [ -z "$HG_DEVICE" ]; then
    echo "错误: 密码和设备名称不能为空"
    exit 1
fi

# 更新系统
echo "更新系统包..."
apt-get update && apt-get upgrade -y
if [ $? -ne 0 ]; then
    echo "错误: 系统更新失败，请检查网络"
    exit 1
fi

# 安装Docker依赖
echo "安装Docker依赖..."
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
if [ $? -ne 0 ]; then
    echo "错误: 安装依赖失败"
    exit 1
fi

# 添加Docker GPG密钥
echo "添加Docker GPG密钥..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
if [ $? -ne 0 ]; then
    echo "错误: 添加GPG密钥失败"
    exit 1
fi

# 添加Docker仓库
echo "添加Docker仓库..."
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
if [ $? -ne 0 ]; then
    echo "错误: 添加Docker仓库失败"
    exit 1
fi

# 安装Docker
echo "安装Docker..."
apt-get update
apt-get install -y docker-ce
if [ $? -ne 0 ]; then
    echo "错误: 安装Docker失败"
    exit 1
fi

# 启动并设置Docker开机自启
echo "启动Docker服务..."
systemctl start docker
systemctl enable docker
if [ $? -ne 0 ]; then
    echo "错误: 启动Docker服务失败"
    exit 1
fi

# 验证Docker安装
echo "验证Docker安装..."
docker_version=$(docker --version)
if [ $? -eq 0 ]; then
    echo "Docker安装成功: $docker_version"
else
    echo "错误: Docker安装失败"
    exit 1
fi

# 拉取Honeygain镜像
echo "拉取Honeygain Docker镜像..."
docker pull honeygain/honeygain
if [ $? -ne 0 ]; then
    echo "错误: 拉取Honeygain镜像失败，请检查网络"
    exit 1
fi

# 运行Honeygain容器
echo "运行Honeygain容器..."
docker run -d --restart unless-stopped --name honeygain_$HG_DEVICE honeygain/honeygain -tou-accept -email "$HG_EMAIL" -pass "$HG_PASSWORD" -device "$HG_DEVICE"
if [ $? -ne 0 ]; then
    echo "错误: 启动Honeygain容器失败，请检查密码或设备名称"
    exit 1
fi

# 验证容器运行
echo "验证容器状态..."
sleep 5
container_status=$(docker ps -q -f name=honeygain_$HG_DEVICE)
if [ -n "$container_status" ]; then
    echo "Honeygain容器运行成功！容器名称: honeygain_$HG_DEVICE"
else
    echo "错误: 容器未运行，请检查日志: docker logs honeygain_$HG_DEVICE"
    exit 1
fi

# 安装Watchtower以自动更新镜像（可选）
echo "安装Watchtower以自动更新Honeygain镜像..."
docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower
if [ $? -eq 0 ]; then
    echo "Watchtower安装成功，Honeygain镜像将自动更新"
else
    echo "警告: Watchtower安装失败，可手动更新镜像"
fi

# 提供使用提示
echo "===== 安装完成！ ====="
echo "1. 检查收益: 登录 https://dashboard.honeygain.com/ (邮箱: $HG_EMAIL)"
echo "2. 查看容器日志: docker logs honeygain_$HG_DEVICE"
echo "3. 停止容器: docker stop honeygain_$HG_DEVICE"
echo "4. 删除容器: docker rm honeygain_$HG_DEVICE"
echo "5. 日志文件: $LOG_FILE"
echo "6. 优化建议: 使用高速网络(50Mbps+)、美国VPS、多IP，参与推荐计划"
echo "===== 安装结束: $(date) ====="

exit 0

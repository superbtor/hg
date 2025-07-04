#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 恢复默认颜色

# 配置参数（直接修改此处）
EMAIL="superbtor2@gmail.com"
PASSWORD="WsxAsd123123"
DEVICE_NAME="c2"
CONTAINER_NAME="honeygain"
IMAGE_NAME="honeygain/honeygain"

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ 错误：Docker 未安装！${NC}"
        echo -e "请运行以下命令安装 Docker："
        echo -e "Ubuntu/Debian: ${YELLOW}sudo apt-get update && sudo apt-get install -y docker.io${NC}"
        echo -e "CentOS/RHEL: ${YELLOW}sudo yum install -y docker-ce && sudo systemctl start docker${NC}"
        exit 1
    fi

    if ! systemctl is-active --quiet docker; then
        echo -e "${YELLOW}⚠️ Docker 服务未运行，正在启动...${NC}"
        sudo systemctl start docker
    fi
}

# 清理旧容器（如果存在）
cleanup() {
    if docker ps -a | grep -q ${CONTAINER_NAME}; then
        echo -e "${YELLOW}⚠️ 发现已存在的 ${CONTAINER_NAME} 容器，正在清理...${NC}"
        docker stop ${CONTAINER_NAME} >/dev/null 2>&1
        docker rm ${CONTAINER_NAME} >/dev/null 2>&1
    fi
}

# 主部署函数
deploy() {
    echo -e "\n${GREEN}🚀 开始部署 Honeygain 容器...${NC}"
    echo -e "邮箱: ${YELLOW}${EMAIL}${NC}"
    echo -e "设备名: ${YELLOW}${DEVICE_NAME}${NC}"

    # 拉取镜像
    echo -e "\n${YELLOW}🔍 拉取镜像 ${IMAGE_NAME}...${NC}"
    docker pull ${IMAGE_NAME} || {
        echo -e "${RED}❌ 镜像拉取失败！请检查网络或镜像名称。${NC}"
        exit 1
    }

    # 运行容器
    echo -e "\n${YELLOW}🛠️ 启动容器 ${CONTAINER_NAME}...${NC}"
    docker run -d \
        --name ${CONTAINER_NAME} \
        --restart unless-stopped \
        ${IMAGE_NAME} \
        -email ${EMAIL} \
        -pass ${PASSWORD} \
        -device ${DEVICE_NAME}

    # 验证状态
    sleep 3 # 等待容器初始化
    if docker ps | grep -q ${CONTAINER_NAME}; then
        echo -e "\n${GREEN}✅ Honeygain 容器已成功运行！${NC}"
        echo -e "使用以下命令查看日志：${YELLOW}docker logs ${CONTAINER_NAME}${NC}"
        echo -e "停止容器：${YELLOW}docker stop ${CONTAINER_NAME}${NC}"
    else
        echo -e "${RED}❌ 容器启动失败！请检查错误：${NC}"
        docker logs ${CONTAINER_NAME}
    fi
}

# 执行主流程
check_docker
cleanup
deploy

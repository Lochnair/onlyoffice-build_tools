FROM ubuntu:18.04

# 设置时区（避免交互式提示）
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 更新并安装基础工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        sudo \
        lsb-release \
        software-properties-common \
        gnupg \
        python \
        python3 \
        build-essential \
        x11-utils && \
    rm -rf /var/lib/apt/lists/*

# 添加 Universe 仓库（Ubuntu 18.04 默认可能未启用）
RUN add-apt-repository universe

# 添加 LLVM 12 的官方源（适用于 Ubuntu 18.04 "Bionic"）
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main" > /etc/apt/sources.list.d/llvm.list

# 安装 LLVM/Clang 12
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        clang-12 \
        lld-12 \
        llvm-12 && \
    rm -rf /var/lib/apt/lists/*

# 确保 Python 2 是默认的（兼容旧脚本）
RUN rm -f /usr/bin/python && ln -s /usr/bin/python2 /usr/bin/python

# 复制本地文件到容器
COPY . /build_tools
WORKDIR /build_tools

# 定义构建参数（BRANCH, PLATFORM, HTTP_PROXY, HTTPS_PROXY）
ARG BRANCH
ARG PLATFORM
ARG HTTP_PROXY
ARG HTTPS_PROXY

# 设置环境变量（包括代理）
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV BRANCH=${BRANCH}
ENV PLATFORM=${PLATFORM}

# 运行自动化脚本
CMD cd tools/linux && \
    BRANCH_ARG=${BRANCH:+--branch=$BRANCH} && \
    PLATFORM_ARG=${PLATFORM:+--platform=$PLATFORM} && \
    python3 ./automate.py $BRANCH_ARG $PLATFORM_ARG

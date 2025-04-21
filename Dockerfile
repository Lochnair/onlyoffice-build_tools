FROM ubuntu:18.04

# 设置软件源（使用官方 Ubuntu 源）
RUN if [ "$(uname -m)" = "aarch64" ]; then \
        echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic main restricted universe multiverse" > /etc/apt/sources.list && \
        echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
        echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
        echo "deb http://ports.ubuntu.com/ubuntu-ports/ bionic-security main restricted universe multiverse" >> /etc/apt/sources.list; \
    else \
        echo "deb http://archive.ubuntu.com/ubuntu/ bionic main restricted universe multiverse" > /etc/apt/sources.list && \
        echo "deb http://archive.ubuntu.com/ubuntu/ bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
        echo "deb http://archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
        echo "deb http://security.ubuntu.com/ubuntu/ bionic-security main restricted universe multiverse" >> /etc/apt/sources.list; \
    fi

# 设置时区
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 启用 universe 仓库并安装基础工具
RUN apt-get update && \
    apt-get install -y software-properties-common ca-certificates && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y python python3 wget sudo lsb-release gnupg && \
    rm -rf /var/lib/apt/lists/*

# 单独安装 libglib2.0-dev
RUN apt-get update && apt-get install -y libglib2.0-dev && rm -rf /var/lib/apt/lists/*

# 安装其他开发依赖
RUN apt-get update && \
    apt-get install -y \
    autoconf2.13 cmake curl git libtool \
    libglu1-mesa-dev libgtk-3-dev libpulse-dev \
    p7zip-full subversion libasound2-dev libatspi2.0-dev \
    libcups2-dev libdbus-1-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libx11-xcb-dev libxi-dev libxrender-dev libxss1 || \
    { echo "Failed package installation"; apt-cache search glib-2.0-dev; exit 1; } && \
    rm -rf /var/lib/apt/lists/*

# 添加 LLVM 仓库并安装 clang-12
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install -y clang-12 lld-12 llvm-12 && \
    rm -rf /var/lib/apt/lists/*

# 设置 Python 链接
RUN rm /usr/bin/python && ln -s /usr/bin/python2 /usr/bin/python

# 工作目录
ADD . /build_tools
WORKDIR /build_tools

# 构建参数
ARG BRANCH
ARG PLATFORM
ARG HTTP_PROXY
ARG HTTPS_PROXY

ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV BRANCH=${BRANCH}
ENV PLATFORM=${PLATFORM}

# 执行构建命令
CMD cd tools/linux && \
    if [ -n "$BRANCH" ]; then \
        BRANCH_ARG="--branch=${BRANCH}"; \
    else \
        BRANCH_ARG=""; \
    fi && \
    if [ -n "$PLATFORM" ]; then \
        PLATFORM_ARG="--platform=${PLATFORM}"; \
    else \
        PLATFORM_ARG=""; \
    fi && \
    python3 ./automate.py $BRANCH_ARG $PLATFORM_ARG

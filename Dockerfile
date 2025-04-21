FROM ubuntu:18.04

# 设置时区
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 更新软件源并安装基础工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        wget \
        gnupg \
        ca-certificates \
        curl \
        sudo

# 启用所有官方仓库
RUN add-apt-repository -y universe && \
    add-apt-repository -y multiverse && \
    apt-get update

# 安装 LLVM 12
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        clang-12 \
        lld-12 \
        llvm-12

# 安装所有依赖项（修正后的包名）
RUN apt-get install -y \
    git \
    cmake \
    libtool \
    p7zip-full \
    subversion \
    libglib2.0-dev \
    libglu1-mesa-dev \
    libgtk-3-dev \
    libpulse-dev \
    libasound2-dev \
    libatspi2.0-dev \
    libcups2-dev \
    libdbus-1-dev \
    libicu-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libx11-xcb-dev \
    libxi-dev \
    libxrender-dev \
    libxss-dev \
    autoconf

# 清理缓存
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 复制代码并运行
COPY . /build_tools
WORKDIR /build_tools

CMD ["/bin/bash"]  # 或你的启动命令

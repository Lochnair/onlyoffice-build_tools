FROM ubuntu:18.04

# 1. 基础配置
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 2. 修复证书和更新问题
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        wget

# 3. 安装基础工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ubuntu-standard \
        build-essential \
        python \
        python3 \
        sudo && \
    apt-get clean

# 4. 修复Python符号链接
RUN rm -f /usr/bin/python && ln -s /usr/bin/python2 /usr/bin/python

# 5. 安装LLVM 12（修复版）
RUN wget -O /tmp/llvm.key https://apt.llvm.org/llvm-snapshot.gpg.key && \
    apt-key add /tmp/llvm.key && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main" > /etc/apt/sources.list.d/llvm.list && \
    rm -f /tmp/llvm.key && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        clang-12 \
        lld-12 \
        llvm-12

# 6. 清理工作
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 7. 复制构建工具
COPY . /build_tools
WORKDIR /build_tools

# 8. 启动命令
CMD ["/bin/bash", "-c", "cd tools/linux && python3 ./automate.py ${BRANCH:+--branch=$BRANCH} ${PLATFORM:+--platform=$PLATFORM}"]

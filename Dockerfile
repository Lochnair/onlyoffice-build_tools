FROM ubuntu:18.04

# 1. Basic configuration - Set timezone
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 2. Force clean package sources and rebuild configuration (critical step)
RUN rm -rf /var/lib/apt/lists/* && \
    echo "deb http://archive.ubuntu.com/ubuntu bionic main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu bionic-security main restricted universe multiverse" >> /etc/apt/sources.list

# 3. Install base tools with forced update and retries
RUN apt-get update -o Acquire::Retries=3 && \
    apt-get install -y --no-install-recommends \
        sudo \
        software-properties-common \
        wget \
        gnupg \
        ca-certificates && \
    echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 4. Add required repositories
RUN add-apt-repository -y universe && \
    add-apt-repository -y multiverse && \
    apt-get update

# 5. Install LLVM from official source
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        clang-12 \
        lld-12 \
        llvm-12

# 6. Install main dependencies (single step)
RUN apt-get update && \
    apt-get install -y \
        git \
        cmake \
        curl \
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

# 7. Install autoconf2.13 from Debian packages
RUN wget http://ftp.debian.org/debian/pool/main/a/autoconf/autoconf_2.13-5_all.deb && \
    dpkg -i autoconf_2.13-5_all.deb || apt-get install -f -y && \
    rm autoconf_2.13-5_all.deb

# 8. Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 9. Copy build tools
COPY . /build_tools
WORKDIR /build_tools

# 10. Set entrypoint with parameter handling
CMD ["/bin/bash", "-c", "cd tools/linux && python3 ./automate.py ${BRANCH:+--branch=$BRANCH} ${PLATFORM:+--platform=$PLATFORM}"]

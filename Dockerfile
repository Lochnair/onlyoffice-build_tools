FROM ubuntu:18.04

# 1. Basic configuration - Set timezone
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 2. Update package lists and install essential tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        software-properties-common \
        wget \
        gnupg \
        ca-certificates && \
    echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 3. Add universe and multiverse repositories
RUN add-apt-repository -y universe && \
    add-apt-repository -y multiverse && \
    apt-get update

# 4. Install LLVM 12 from official repository
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        clang-12 \
        lld-12 \
        llvm-12

# 5. Install main build dependencies
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

# 6. Install autoconf2.13 from Ubuntu's repositories
RUN apt-get update && \
    apt-get install -y autoconf2.13 || \
    (wget http://archive.ubuntu.com/ubuntu/pool/universe/a/autoconf/autoconf_2.13-4_all.deb && \
     dpkg -i autoconf_2.13-4_all.deb || apt-get install -f -y)

# 7. Clean up package cache
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 8. Copy build tools into container
COPY . /build_tools
WORKDIR /build_tools

# 9. Set entrypoint with parameter handling
CMD ["/bin/bash", "-c", "cd tools/linux && python3 ./automate.py ${BRANCH:+--branch=$BRANCH} ${PLATFORM:+--platform=$PLATFORM}"]

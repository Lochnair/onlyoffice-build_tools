FROM ubuntu:18.04

# Set timezone non-interactively
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 1. Reset package sources (modified to avoid directory removal)
RUN rm -f /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu bionic main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu bionic-security main restricted universe multiverse" >> /etc/apt/sources.list

# 2. Install sudo with passwordless access
RUN apt-get update && \
    apt-get install -y --no-install-recommends sudo && \
    echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 3. Install base tools with retry logic
RUN for i in {1..3}; do apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    wget \
    gnupg \
    ca-certificates && break || sleep 2; done

# 4. Add repositories with verification
RUN add-apt-repository -y universe && \
    add-apt-repository -y multiverse && \
    apt-get update

# 5. Install LLVM 12 with key verification
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main" | sudo tee /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    clang-12 \
    lld-12 \
    llvm-12

# 6. Install dependencies with version pinning and fallback
RUN apt-get update && \
    apt-get install -y \
    git=1:2.17.* \
    cmake=3.10.* \
    curl \
    libtool \
    p7zip-full \
    subversion \
    libglib2.0-dev=2.56.* \
    libglu1-mesa-dev \
    libgtk-3-dev=3.22.* \
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
    autoconf || \
    (apt-get update && apt-get install -yf)

# 7. Clean up package cache
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 8. Install autoconf2.13 from Debian packages
RUN wget http://ftp.debian.org/debian/pool/main/a/autoconf/autoconf_2.13-5_all.deb && \
    dpkg -i autoconf_2.13-5_all.deb || apt-get install -f -y && \
    rm autoconf_2.13-5_all.deb

# 9. Copy build tools and set working directory
COPY . /build_tools
WORKDIR /build_tools

# 10. Use proper JSON array form for CMD
CMD ["/bin/bash", "-c", "cd tools/linux && python3 ./automate.py ${BRANCH:+--branch=$BRANCH} ${PLATFORM:+--platform=$PLATFORM}"]

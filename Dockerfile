FROM ubuntu:18.04

# Set timezone non-interactively
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 1. Auto-detect system architecture and configure appropriate package sources
RUN ARCH=$(dpkg --print-architecture) && \
    echo "Configuring for architecture: $ARCH" && \
    echo "deb http://archive.ubuntu.com/ubuntu bionic main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu bionic-security main restricted universe multiverse" >> /etc/apt/sources.list

# 2. Install sudo with passwordless access (with retry mechanism)
RUN for i in {1..3}; do \
    apt-get update && \
    apt-get install -y --no-install-recommends sudo && \
    echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    break || sleep 2; \
    done

# 3. Install essential build tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    wget \
    gnupg \
    ca-certificates

# 4. Add universe and multiverse repositories
RUN add-apt-repository -y universe && \
    add-apt-repository -y multiverse && \
    apt-get update

# 5. Install LLVM 12 (architecture-aware)
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    clang-12 \
    lld-12 \
    llvm-12

# 6. Install main dependencies (architecture-aware)
RUN apt-get update && apt-get install -y \
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

# 7. Clean up package cache
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 8. Install autoconf2.13 (multi-architecture compatible approach)
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        wget http://ftp.debian.org/debian/pool/main/a/autoconf/autoconf_2.13-5_all.deb && \
        dpkg -i autoconf_2.13-5_all.deb || apt-get install -f -y && \
        rm autoconf_2.13-5_all.deb; \
    elif [ "$ARCH" = "arm64" ]; then \
        wget http://ports.ubuntu.com/ubuntu-ports/pool/universe/a/autoconf/autoconf_2.13-4_all.deb && \
        dpkg -i autoconf_2.13-4_all.deb || apt-get install -f -y && \
        rm autoconf_2.13-4_all.deb; \
    else \
        echo "Unsupported architecture: $ARCH"; exit 1; \
    fi

# 9. Copy build tools into container
COPY . /build_tools
WORKDIR /build_tools

# 10. Set entrypoint with parameter handling
CMD ["/bin/bash", "-c", "cd tools/linux && python3 ./automate.py ${BRANCH:+--branch=$BRANCH} ${PLATFORM:+--platform=$PLATFORM}"]

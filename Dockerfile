FROM ubuntu:18.04

# Set timezone (non-interactive)
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install basic tools and enable repositories
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        wget \
        gnupg \
        ca-certificates && \
    add-apt-repository -y universe && \
    add-apt-repository -y multiverse && \
    apt-get update

# Install LLVM 12
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        clang-12 \
        lld-12 \
        llvm-12

# Install dependencies with corrected package names
RUN apt-get install -y \
    git \
    cmake \
    curl \
    libtool \
    p7zip-full \
    subversion \
    libglib2.0-dev \          # Correct package name for glib-2.0-dev
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
    autoconf && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install autoconf2.13 manually if needed
RUN wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.13.tar.gz && \
    tar -xzf autoconf-2.13.tar.gz && \
    cd autoconf-2.13 && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf autoconf-2.13*

# Copy build tools
COPY . /build_tools
WORKDIR /build_tools

# Use JSON array form for CMD
CMD ["/bin/bash", "-c", "cd tools/linux && python3 ./automate.py ${BRANCH:+--branch=$BRANCH} ${PLATFORM:+--platform=$PLATFORM}"]

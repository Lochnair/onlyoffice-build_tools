FROM ubuntu:18.04
    
# 1. Basic configuration - Set timezone
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ubuntu-standard \
        build-essential \
        python \
        python3 \
        sudo && \
    apt-get clean

RUN rm /usr/bin/python && ln -s /usr/bin/python2 /usr/bin/python
 

# 4. Install LLVM 12 from official repository
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        clang-12 \
        lld-12 \
        llvm-12
        


# 7. Clean up package cache
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 8. Copy build tools into container
COPY . /build_tools
WORKDIR /build_tools

# 9. Set entrypoint with parameter handling
CMD ["/bin/bash", "-c", "cd tools/linux && python3 ./automate.py ${BRANCH:+--branch=$BRANCH} ${PLATFORM:+--platform=$PLATFORM}"]

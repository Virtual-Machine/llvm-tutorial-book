FROM crystallang/crystal:0.21.0



RUN apt-get update && \
    apt-get install -y build-essential curl libevent-dev git libxml2-dev \
    clang-3.6 libedit-dev libncurses-dev clang && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /root/.cache/crystal

ADD . /opt/llvm-tutorial
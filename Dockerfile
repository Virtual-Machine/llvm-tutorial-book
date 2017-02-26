FROM crystallang/crystal:0.21.0



RUN apt-get update && \
    apt-get install clang-3.9 lldb-3.9 llvm-3.9 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /root/.cache/crystal

ADD . /opt/llvm-tutorial
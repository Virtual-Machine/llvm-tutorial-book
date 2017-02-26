FROM crystallang/crystal:0.21.0

RUN apt-get update && \
    apt-get install -y wget

RUN wget -O - http://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add - && \
	apt-get update && \
	apt-get install clang-3.9 lldb-3.9


RUN apt-get update && \
    apt-get install -y build-essential curl libevent-dev git libxml2-dev \
    libedit-dev libncurses-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /root/.cache/crystal

ADD . /opt/llvm-tutorial
FROM crystallang/crystal:0.21.0



RUN apt-get update && \
    apt-get install clang-5.0 clang-5.0-doc libclang-common-5.0-dev libclang-5.0-dev libclang1-5.0 libclang1-5.0-dbg libllvm-5.0-ocaml-dev libllvm5.0 libllvm5.0-dbg lldb-5.0 llvm-5.0 llvm-5.0-dev llvm-5.0-runtime clang-format-5.0 python-clang-5.0 liblldb-5.0-dbg lld-5.0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /root/.cache/crystal

ADD . /opt/llvm-tutorial
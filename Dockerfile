from golang:1.17 as builder

RUN apt update && apt install clang -y

COPY . /go/pilosa

# install source of target
RUN mkdir ~/gopath && \
    export GOPATH="$HOME/gopath" && \
    export PATH="$PATH:$GOPATH/bin" && \
    cd /go/pilosa/ && \
    make install-build-deps && \
    make install && \
    cd /go/pilosa/roaring && \
    go get -u github.com/dvyukov/go-fuzz/go-fuzz github.com/dvyukov/go-fuzz/go-fuzz-build && \
    go-fuzz-build -libfuzzer --func FuzzRoaringOps -o fuzz_roaring_ops.a . && \
    clang -fsanitize=fuzzer fuzz_roaring_ops.a  -o fuzz_roaring_ops && \
    cp fuzz_roaring_ops /fuzz_roaring_ops

FROM golang:1.17
COPY --from=builder /fuzz_roaring_ops /

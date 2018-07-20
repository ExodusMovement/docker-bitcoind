FROM alpine:3.8

RUN addgroup -g 1000 bitcoind \
  && adduser -u 1000 -G bitcoind -s /bin/sh -D bitcoind

RUN apk add --no-cache \
    boost \
    boost-program_options \
    openssl \
    libevent \
    zeromq \
  && apk add --no-cache --virtual /.build-deps \
    autoconf \
    automake \
    boost-dev \
    build-base \
    openssl-dev \
    libevent-dev \
    libtool \
    zeromq-dev \
  && mkdir build \
  && cd build \
  && wget -O bitcoind.tar.gz https://github.com/bitcoin/bitcoin/archive/v0.16.1.tar.gz \
  && tar -xf bitcoind.tar.gz \
  && cd bitcoin-0.16.1 \
  && ./autogen.sh \
  && ./configure \
    --disable-shared \
    --disable-static \
    --disable-wallet \
    --disable-tests \
    --disable-bench \
    --enable-zmq \
    --with-utils \
    --without-libs \
    --without-gui \
  && make -j$(nproc) \
  && strip -o /home/bitcoind/bitcoind src/bitcoind \
  && strip -o /home/bitcoind/bitcoin-cli src/bitcoin-cli \
  && chown bitcoind /home/bitcoind/bitcoin* \
  && rm -rf /build \
  && apk del /.build-deps

USER bitcoind

# P2P & RPC
EXPOSE 8333 8332

WORKDIR /home/bitcoind
ENTRYPOINT ["./bitcoind"]

FROM alpine:3.8 AS builder

RUN apk add --no-cache \
    autoconf \
    automake \
    boost-dev \
    build-base \
    openssl-dev \
    libevent-dev \
    libtool \
    zeromq-dev

RUN wget -qO- https://github.com/bitcoin/bitcoin/archive/v0.16.2.tar.gz | tar xz
WORKDIR /bitcoin-0.16.2

RUN ./autogen.sh
RUN ./configure \
  --disable-shared \
  --disable-static \
  --disable-wallet \
  --disable-tests \
  --disable-bench \
  --enable-zmq \
  --with-utils \
  --without-libs \
  --without-gui
RUN make -j$(nproc)
RUN strip src/bitcoind src/bitcoin-cli


FROM alpine:3.8

RUN apk add --no-cache \
  boost \
  boost-program_options \
  openssl \
  libevent \
  zeromq

RUN addgroup -g 1000 bitcoind \
  && adduser -u 1000 -G bitcoind -s /bin/sh -D bitcoind

USER bitcoind

RUN mkdir -p /home/bitcoind/.bitcoin

WORKDIR /home/bitcoind
COPY --chown=bitcoind:bitcoind --from=builder /bitcoin-0.16.2/src/bitcoind /bitcoin-0.16.2/src/bitcoin-cli ./

# P2P & RPC
EXPOSE 8333 8332

ENV \
  BITCOIND_DBCACHE=450 \
  BITCOIND_PAR=0 \
  BITCOIND_PORT=8333 \
  BITCOIND_RPC_PORT=8332 \
  BITCOIND_RPC_THREADS=4 \
  BITCOIND_ARGUMENTS=""

CMD exec ./bitcoind \
  -dbcache=$BITCOIND_DBCACHE \
  -par=$BITCOIND_PAR \
  -port=$BITCOIND_PORT \
  -rpcport=$BITCOIND_RPC_PORT \
  -rpcthreads=$BITCOIND_RPC_THREADS \
  $BITCOIND_ARGUMENTS

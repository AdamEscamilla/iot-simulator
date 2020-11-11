FROM ubuntu:18.04 AS devtools

# Number of CPUs
ARG NCPU=1

RUN apt-get update
RUN apt-get install -y \
    autoconf \
    build-essential \
    clang \
    clang-tidy \
    curl \
    cmake \
    doxygen \
    gcc \
    git \
    libssl-dev \
    libtool \
    pkg-config \
    unzip \
    wget \
    && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /dep
WORKDIR /dep

# Add JSON library (~10M)
RUN git clone https://github.com/akheron/jansson jansson
RUN cd jansson && \
    cmake . && \
    make -j ${NCPU} && \
    make install

# Add OPENSSL library (~1H)
RUN git clone https://github.com/openssl/openssl openssl
RUN cd openssl && \
    ./config && \
    make -j ${NCPU} && \
    make install

# Add JWT library (-1M)
RUN git clone https://github.com/benmcollins/libjwt libjwt
RUN cd libjwt && \
    autoreconf -i && \
    ./configure && \
    make -j ${NCPU} && \
    make install

RUN git clone https://github.com/eclipse/paho.mqtt.c paho.mqtt.c
RUN cd paho.mqtt.c && \
    cmake -DPAHO_WITH_SSL=TRUE \
          -DPAHO_BUILD_DOCUMENTATION=TRUE \
          -DPAHO_BUILD_SAMPLES=TRUE . && \
    make all -j ${NCPU} && \
    make install

FROM devtools AS build

RUN mkdir /build
WORKDIR /build

COPY clang-tidy .clang-tidy
COPY Makefile .
COPY mqtt_client.c .

RUN OPENSSL_DIR=/usr/local/lib make

RUN wget -O ca.crt https://pki.google.com/roots.pem

#FROM scratch
#WORKDIR /

#COPY --from=build /build/client .
#COPY --from=build /build/ca.crt .
COPY client.key .

ENV LD_LIBRARY_PATH=/usr/local/lib
ENV LD_RUN_PATH=/usr/local/lib

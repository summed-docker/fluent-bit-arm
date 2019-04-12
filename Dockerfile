FROM arm32v7/debian:stretch as builder

# Fluent Bit version
ENV FLB_MAJOR 1
ENV FLB_MINOR 0
ENV FLB_PATCH 6
ENV FLB_VERSION 1.0.6

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      make \
      wget \
      unzip \
      libssl1.0-dev \
      libasl-dev \
      libsasl2-dev \
      pkg-config \
      libsystemd-dev \
      zlib1g-dev \
	  git \
	  ca-certificates

RUN mkdir -p /fluent-bit/bin /fluent-bit/etc /fluent-bit/log /tmp/src/

RUN git clone -b v$FLB_VERSION --depth 1 https://github.com/fluent/fluent-bit.git /tmp/src

RUN rm -rf /tmp/src/build/*

WORKDIR /tmp/src/build/

RUN apt-get install -y flex
RUN apt-get install -y bison
RUN cmake -DFLB_DEBUG=Off \
          -DFLB_TRACE=Off \
          -DFLB_JEMALLOC=On \
          -DFLB_BUFFERING=On \
          -DFLB_TLS=On \
          -DFLB_SHARED_LIB=Off \
          -DFLB_EXAMPLES=Off \
          -DFLB_HTTP_SERVER=On \
          -DFLB_IN_SYSTEMD=On \
          -DFLB_OUT_KAFKA=On ..

RUN make -j $(getconf _NPROCESSORS_ONLN)
RUN install bin/fluent-bit /fluent-bit/bin/

# Configuration files
RUN cp \
/tmp/src/conf/* \
/fluent-bit/etc/

# Add custom configuration files
COPY ./conf/* /fluent-bit/etc/

FROM arm32v7/debian:stable-slim

MAINTAINER Eduardo Silva <eduardo@treasure-data.com>
LABEL Description="Fluent Bit docker image" Vendor="Fluent Organization" Version="1.1"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
   apt-get install -y --no-install-recommends \
   libssl1.0-dev \
   libsasl2-dev \
   ca-certificates

COPY --from=builder /fluent-bit /fluent-bit

#
EXPOSE 2020

# Entry point
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]
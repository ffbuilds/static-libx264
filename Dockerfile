# syntax=docker/dockerfile:1

# x264 only have a stable branch no tags and we checkout commit so no hash is needed
# bump: x264 /X264_VERSION=([[:xdigit:]]+)/ gitrefs:https://code.videolan.org/videolan/x264.git|re:#^refs/heads/stable$#|@commit
# bump: x264 after ./hashupdate Dockerfile X264 $LATEST
# bump: x264 link "Source diff $CURRENT..$LATEST" https://code.videolan.org/videolan/x264/-/compare/$CURRENT...$LATEST
ARG X264_URL="https://code.videolan.org/videolan/x264.git"
ARG X264_VERSION=baee400fa9ced6f5481a728138fed6e867b0ff7f

# Must be specified
ARG ALPINE_VERSION

FROM alpine:${ALPINE_VERSION} AS base

FROM base AS download
ARG X264_URL
ARG X264_VERSION
WORKDIR /tmp
RUN \
  apk add --no-cache --virtual download \
    git && \
  git clone "$X264_URL" && \
  cd x264 && \
  git checkout $X264_VERSION && \
  apk del download

FROM base AS build 
COPY --from=download /tmp/x264/ /tmp/x264/
WORKDIR /tmp/x264
RUN \
  apk add --no-cache --virtual build \
    build-base bash nasm pkgconf && \
  ./configure --enable-pic --enable-static --disable-cli --disable-lavf --disable-swscale && \
  make -j$(nproc) install && \
  # Sanity tests
  pkg-config --exists --modversion --path x264 && \
  ar -t /usr/local/lib/libx264.a && \
  readelf -h /usr/local/lib/libx264.a && \
  # Cleanup
  apk del build

FROM scratch
ARG X264_VERSION
COPY --from=build /usr/local/lib/pkgconfig/x264.pc /usr/local/lib/pkgconfig/x264.pc
COPY --from=build /usr/local/lib/libx264.a /usr/local/lib/libx264.a
COPY --from=build /usr/local/include/x264*.h /usr/local/include/

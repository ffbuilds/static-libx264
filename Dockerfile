
# x264 only have a stable branch no tags and we checkout commit so no hash is needed
# bump: x264 /X264_VERSION=([[:xdigit:]]+)/ gitrefs:https://code.videolan.org/videolan/x264.git|re:#^refs/heads/stable$#|@commit
# bump: x264 after ./hashupdate Dockerfile X264 $LATEST
# bump: x264 link "Source diff $CURRENT..$LATEST" https://code.videolan.org/videolan/x264/-/compare/$CURRENT...$LATEST
ARG X264_URL="https://code.videolan.org/videolan/x264.git"
ARG X264_VERSION=baee400fa9ced6f5481a728138fed6e867b0ff7f

# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM alpine:3.16.2 AS base

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
    build-base bash nasm && \
  ./configure --enable-pic --enable-static --disable-cli --disable-lavf --disable-swscale && \
  make -j$(nproc) install && \
  apk del build

FROM scratch
ARG X264_VERSION
COPY --from=build /usr/local/lib/pkgconfig/x264.pc /usr/local/lib/pkgconfig/x264.pc
COPY --from=build /usr/local/lib/libx264.a /usr/local/lib/libx264.a
COPY --from=build /usr/local/include/x264*.h /usr/local/include/

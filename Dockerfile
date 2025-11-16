FROM alpine

ARG UID=1000
ARG GID=1000

RUN apk add --no-cache openjdk21 ffmpeg && \
    addgroup -g ${GID} jdownloader && \
    adduser -D -u ${UID} -G jdownloader jdownloader

ADD scripts/entrypoint.sh /entrypoint.sh
ADD config /JDownloader/cfg

RUN mkdir -p /Downloads && \
    chown -R jdownloader:jdownloader /JDownloader /Downloads

VOLUME /JDownloader/cfg
VOLUME /Downloads

EXPOSE 3129

USER jdownloader
WORKDIR /JDownloader
ENTRYPOINT ["/entrypoint.sh"]

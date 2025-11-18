FROM alpine

ARG UID=1000
ARG GID=1000

RUN apk add --no-cache openjdk21-jre ffmpeg jq && \
    addgroup -g ${GID} jdownloader && \
    adduser -D -u ${UID} -G jdownloader jdownloader

ADD entrypoint.sh /entrypoint.sh
ADD scripts /scripts

RUN mkdir -p /JDownloader /Downloads && \
    chown -R jdownloader:jdownloader /JDownloader /Downloads

VOLUME /JDownloader
VOLUME /Downloads

EXPOSE 3129

USER jdownloader
WORKDIR /JDownloader
ENTRYPOINT ["/entrypoint.sh"]

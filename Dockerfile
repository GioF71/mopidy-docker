ARG BASE_IMAGE
FROM ${BASE_IMAGE:-ubuntu:jammy} AS BASE

RUN apt-get update
RUN apt-get install -y wget
RUN mkdir -p /etc/apt/keyrings
RUN wget -q -O /etc/apt/keyrings/mopidy-archive-keyring.gpg https://apt.mopidy.com/mopidy.gpg
RUN wget -q -O /etc/apt/sources.list.d/mopidy.list https://apt.mopidy.com/bullseye.list
RUN apt-get update

RUN apt-get install -y mopidy
RUN apt-get install -y python3-pip

RUN apt-get install -y alsa-utils

#RUN apt-get install -y python3-venv
#RUN python3 -m venv /opt/mopidy-venv
#ENV PATH="/opt/mopidy-venv/bin:$PATH"

# extensions
RUN python3 -m pip install --upgrade Mopidy-Iris
RUN python3 -m pip install --upgrade Mopidy-Tidal
RUN python3 -m pip install --upgrade Mopidy-Local
RUN python3 -m pip install --upgrade Mopidy-Scrobbler
RUN python3 -m pip install --upgrade Mopidy-MPD

RUN apt-get install -y gstreamer1.0-plugins-bad

RUN apt-get install -y mopidy-spotify
RUN python3 -m pip install --upgrade Mopidy-MusicBox-Webclient

RUN mkdir -p /build

COPY build/cleanup.sh /build
RUN chmod u+x /build/cleanup.sh
RUN /build/cleanup.sh
RUN rm /build/cleanup.sh

RUN rmdir /build

#FROM scratch
#COPY --from=BASE / /

LABEL maintainer="GioF71"
LABEL source="https://github.com/GioF71/mopidy-docker"

RUN mkdir -p /app/bin

VOLUME /config
VOLUME /cache
VOLUME /data
VOLUME /music

ENV USER_MODE ""
ENV PUID ""
ENV PGID ""
ENV AUDIO_GID ""

ENV RESTORE_STATE ""

ENV AUDIO_OUTPUT ""

ENV SCROBBLER_ENABLED ""
ENV SCROBBLER_USERNAME ""
ENV SCROBBLER_PASSWORD ""

ENV TIDAL_ENABLED ""
ENV TIDAL_QUALITY ""
ENV TIDAL_LOGIN_SERVER_PORT ""
ENV TIDAL_AUTH_METHOD ""

ENV SPOTIFY_ENABLED ""
ENV SPOTIFY_CLIENT_ID ""
ENV SPOTIFY_SECRET ""
ENV SPOTIFY_USERNAME ""
ENV SPOTIFY_PASSWORD ""

ENV FILE_ENABLED ""
ENV LOCAL_ENABLED ""

ENV MPD_ENABLED ""

COPY app/bin/*.sh /app/bin/
RUN chmod +x /app/bin/*.sh

ENTRYPOINT ["/app/bin/entrypoint.sh"]

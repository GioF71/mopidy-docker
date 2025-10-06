ARG BASE_IMAGE
FROM ${BASE_IMAGE:-ubuntu:noble} AS base

RUN apt-get update
RUN apt-get install -y wget
RUN mkdir -p /etc/apt/keyrings
RUN wget -q -O /etc/apt/keyrings/mopidy-archive-keyring.gpg https://apt.mopidy.com/mopidy.gpg
RUN wget -q -O /etc/apt/sources.list.d/mopidy.list https://apt.mopidy.com/bullseye.list
RUN apt-get update

RUN apt-get install -y mopidy
RUN apt-get install -y python3-pip

RUN apt-get install -y alsa-utils

RUN apt-get install -y python3-venv
RUN python3 -m venv /opt/mopidy-venv
ENV PATH="/opt/mopidy-venv/bin:$PATH"

# extensions
RUN python3 -m pip install --target /opt/mopidy-venv --upgrade Mopidy-Iris
RUN python3 -m pip install --target /opt/mopidy-venv --upgrade Mopidy-Tidal
RUN python3 -m pip install --target /opt/mopidy-venv --upgrade Mopidy-Local
RUN python3 -m pip install --target /opt/mopidy-venv --upgrade Mopidy-Scrobbler
RUN python3 -m pip install --target /opt/mopidy-venv --upgrade Mopidy-MPD
RUN python3 -m pip install --target /opt/mopidy-venv --upgrade mopidy-jellyfin
RUN python3 -m pip install --target /opt/mopidy-venv --upgrade Mopidy-Mobile

RUN apt-get install -y gstreamer1.0-plugins-bad

RUN mkdir -p /build

COPY build/cleanup.sh /build
RUN chmod u+x /build/cleanup.sh
RUN /build/cleanup.sh
RUN rm /build/cleanup.sh

RUN rmdir /build

FROM scratch
COPY --from=base / /

LABEL maintainer="GioF71"
LABEL source="https://github.com/GioF71/mopidy-docker"

RUN mkdir -p /app/bin

VOLUME /config
VOLUME /cache
VOLUME /data
VOLUME /music

ENV USER_MODE=""
ENV PUID=""
ENV PGID=""
ENV AUDIO_GID=""

ENV RESTORE_STATE=""

ENV AUDIO_OUTPUT=""

ENV SCROBBLER_ENABLED=""
ENV SCROBBLER_USERNAME=""
ENV SCROBBLER_PASSWORD=""

ENV TIDAL_ENABLED=""
ENV TIDAL_QUALITY=""
ENV TIDAL_LOGIN_SERVER_PORT=""
ENV TIDAL_LOGIN_METHOD=""
ENV TIDAL_AUTH_METHOD=""
ENV TIDAL_PLAYLIST_CACHE_REFRESH_SECS=""
ENV TIDAL_LAZY=""

ENV JELLYFIN_ENABLED=""
ENV JELLYFIN_HOSTNAME=""
ENV JELLYFIN_USERNAME=""
ENV JELLYFIN_PASSWORD=""
ENV JELLYFIN_LIBRARIES=""

ENV FILE_ENABLED=""
ENV LOCAL_ENABLED=""
ENV LOCAL_MEDIA_DIR=""
ENV LOCAL_MAX_SEARCH_RESULTS=""
ENV LOCAL_SCAN_TIMEOUT=""
ENV LOCAL_SCAN_FOLLOW_SYMLINKS=""
ENV LOCAL_SCAN_FLUSH_THRESHOLD=""
ENV LOCAL_INCLUDED_FILE_EXTENSIONS=""
ENV LOCAL_EXCLUDED_FILE_EXTENSIONS=""
ENV LOCAL_DIRECTORIES=""
ENV LOCAL_TIMEOUT=""
ENV LOCAL_USE_ARTIST_SORTNAME=""
ENV LOCAL_ALBUM_ART_FILES=""

ENV MPD_ENABLED=""

ENV MOBILE_ENABLED=""
ENV MOBILE_TITLE=""
ENV MOBILE_WS_URL=""

ENV LOG_QUIET=""
ENV LOG_VERBOSE=""

ENV PYTHONPATH="/opt/mopidy-venv"
ENV PATH="/opt/mopidy-venv/bin:$PATH"

COPY app/bin/entrypoint.sh /app/bin/
RUN chmod +x /app/bin/entrypoint.sh

ENTRYPOINT ["/app/bin/entrypoint.sh"]

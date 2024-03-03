#!/bin/bash

ENABLE_SPOTIFY=0
if [[ -z "${SPOTIFY_ENABLED}" ]]; then
    ENABLE_SPOTIFY=0
else
    if [[ "${SPOTIFY_ENABLED^^}" == "YES" ]] || [[ "${SPOTIFY_ENABLED^^}" == "Y" ]]; then
        ENABLE_SPOTIFY=1
    elif [[ "${SPOTIFY_ENABLED^^}" != "NO" ]] && [[ "${SPOTIFY_ENABLED^^}" != "N" ]]; then
        echo "Invalid SPOTIFY_ENABLED=[$SPOTIFY_ENABLED]"
        exit 1
    fi
fi

if [[ $ENABLE_SPOTIFY -eq 1 ]]; then
    echo "[spotify]" > $CONFIG_DIR/spotify.conf
    echo "enabled = true" >> $CONFIG_DIR/spotify.conf
    # TODO check valid values? Maybe one day ...
    if [[ -n "${SPOTIFY_CLIENT_ID}" ]]; then
        echo "client_id = ${SPOTIFY_CLIENT_ID}" >> $CONFIG_DIR/spotify.conf
    fi
    if [[ -n "${SPOTIFY_SECRET}" ]]; then
        echo "client_secret = ${SPOTIFY_SECRET}" >> $CONFIG_DIR/spotify.conf
    fi
    if [[ -n "${SPOTIFY_USERNAME}" ]]; then
        echo "username = ${SPOTIFY_USERNAME}" >> $CONFIG_DIR/spotify.conf
    fi
    if [[ -n "${SPOTIFY_PASSWORD}" ]]; then
        echo "password = ${SPOTIFY_PASSWORD}" >> $CONFIG_DIR/spotify.conf
    fi
else
    echo "[spotify]" > $CONFIG_DIR/spotify.conf
    echo "enabled = false" >> $CONFIG_DIR/spotify.conf
fi

cat $CONFIG_DIR/spotify.conf
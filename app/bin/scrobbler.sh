#!/bin/bash

ENABLE_SCROBBLER=0
if [[ -z "${SCROBBLER_ENABLED}" ]]; then
    ENABLE_SCROBBLER=0
else
    if [[ "${SCROBBLER_ENABLED^^}" == "YES" ]] || [[ "${SCROBBLER_ENABLED^^}" == "Y" ]]; then
        ENABLE_SCROBBLER=1
    elif [[ "${SCROBBLER_ENABLED^^}" != "NO" ]] && [[ "${SCROBBLER_ENABLED^^}" != "N" ]]; then
        echo "Invalid SCROBBLER_ENABLED=[$SCROBBLER_ENABLED]"
        exit 1
    fi
fi

if [[ $ENABLE_SCROBBLER -eq 1 ]]; then
    if [[ -n "${SCROBBLER_USERNAME}" ]] && [[ -n "${SCROBBLER_PASSWORD}" ]]; then
        echo "[scrobbler]" > $CONFIG_DIR/scrobbler.conf
        echo "enabled = true" >> $CONFIG_DIR/scrobbler.conf
        echo "username = ${SCROBBLER_USERNAME}" >> $CONFIG_DIR/scrobbler.conf
        echo "password = ${SCROBBLER_PASSWORD}" >> $CONFIG_DIR/scrobbler.conf
    else
        echo "No credentials for the scrobbler plugin"
    fi
else
    echo "[scrobbler]" > $CONFIG_DIR/scrobbler.conf
    echo "enabled = false" >> $CONFIG_DIR/scrobbler.conf
fi


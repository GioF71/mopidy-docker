#!/bin/bash

ENABLE_TIDAL=0
if [[ -z "${TIDAL_ENABLED}" ]]; then
    ENABLE_TIDAL=0
else
    if [[ "${TIDAL_ENABLED^^}" == "YES" ]] || [[ "${TIDAL_ENABLED^^}" == "Y" ]]; then
        ENABLE_TIDAL=1
    elif [[ "${TIDAL_ENABLED^^}" != "NO" ]] && [[ "${TIDAL_ENABLED^^}" != "N" ]]; then
        echo "Invalid TIDAL_ENABLED=[$TIDAL_ENABLED]"
        exit 1
    fi
fi

if [[ $ENABLE_TIDAL -eq 1 ]]; then
    echo "[tidal]" > $CONFIG_DIR/tidal.conf
    echo "enabled = true" >> $CONFIG_DIR/tidal.conf
    if [[ -z "${TIDAL_QUALITY}" ]]; then
        TIDAL_QUALITY=LOSSLESS
    fi
    # TODO check valid values? Maybe one day ...
    echo "quality = ${TIDAL_QUALITY}" >> $CONFIG_DIR/tidal.conf
    if [[ -n "${TIDAL_AUTH_METHOD}" ]]; then
        echo "auth_method = ${TIDAL_AUTH_METHOD}" >> $CONFIG_DIR/tidal.conf
    fi
    if [[ -n "${TIDAL_LOGIN_SERVER_PORT}" ]]; then
        echo "login_server_port = ${TIDAL_LOGIN_SERVER_PORT}" >> $CONFIG_DIR/tidal.conf
    fi
else
    echo "[tidal]" > $CONFIG_DIR/tidal.conf
    echo "enabled = false" >> $CONFIG_DIR/tidal.conf
fi


#!/bin/bash

# error codes
# 1 invalid value

current_user_id=$(id -u)
echo "Current user id is [$current_user_id]"

if [[ $current_user_id -eq 0 ]]; then
    CONFIG_FILE=/config/mopidy.conf
else
    CONFIG_FILE=/tmp/mopidy.conf
fi

DEFAULT_UID=1000
DEFAULT_GID=1000

DEFAULT_USER_NAME=mopidy-user
DEFAULT_GROUP_NAME=mopidy-group
DEFAULT_HOME_DIR=/home/$DEFAULT_USER_NAME

USER_NAME=$DEFAULT_USER_NAME
GROUP_NAME=$DEFAULT_GROUP_NAME
HOME_DIR=$DEFAULT_HOME_DIR

echo "USER_MODE=[${USER_MODE}]"

create_audio_gid() {
    if [ $(getent group $AUDIO_GID) ]; then
        echo "  Group with gid $AUDIO_GID already exists"
    else
        echo "  Creating group with gid $AUDIO_GID"
        groupadd -g $AUDIO_GID mopidy-audio
    fi
    echo "  Adding $USER_NAME to gid $AUDIO_GID"
    AUDIO_GRP=$(getent group $AUDIO_GID | cut -d: -f1)
    echo "  gid $AUDIO_GID -> group $AUDIO_GRP"
    if id -nG "$USER_NAME" | grep -qw "$AUDIO_GRP"; then
        echo "  User $USER_NAME already belongs to group audio (GID ${AUDIO_GID})"
    else
        usermod -a -G $AUDIO_GRP $USER_NAME
        echo "  Successfully added $USER_NAME to group audio (GID ${AUDIO_GID})"
    fi
}

if [[ "${current_user_id}" == "0" && (! (${USER_MODE^^} == "NO" || ${USER_MODE^^} == "N")) ]]; then
    if [[ "${USER_MODE^^}" == "YES" || "${USER_MODE^^}" == "Y" || -n "${PUID}" ]]; then
        USE_USER_MODE="Y"
        echo "User mode enabled"
        echo "Creating user ...";
        if [ -z "${PUID}" ]; then
            PUID=$DEFAULT_UID;
            echo "Setting default value for PUID: ["$PUID"]"
        fi
        if [ -z "${PGID}" ]; then
            PGID=$DEFAULT_GID;
            echo "Setting default value for PGID: ["$PGID"]"
        fi
        echo "Ensuring user with uid:[$PUID] gid:[$PGID] exists ...";
        ### create group if it does not exist
        if [ ! $(getent group $PGID) ]; then
            echo "Group with gid [$PGID] does not exist, creating..."
            groupadd -g $PGID $GROUP_NAME
            echo "Group [$GROUP_NAME] with gid [$PGID] created."
        else
            GROUP_NAME=$(getent group $PGID | cut -d: -f1)
            echo "Group with gid [$PGID] name [$GROUP_NAME] already exists."
        fi
        ### create user if it does not exist
        if [ ! $(getent passwd $PUID) ]; then
            echo "User with uid [$PUID] does not exist, creating..."
            useradd -g $PGID -u $PUID -M $USER_NAME
            echo "User [$USER_NAME] with uid [$PUID] created."
        else
            USER_NAME=$(getent passwd $PUID | cut -d: -f1)
            echo "user with uid [$PUID] name [$USER_NAME] already exists."
            HOME_DIR="/home/$USER_NAME"
        fi
        ### create home directory
        if [ ! -d "$HOME_DIR" ]; then
            echo "Home directory [$HOME_DIR] not found, creating."
            mkdir -p $HOME_DIR
            echo ". done."
        fi
        chown -R $PUID:$PGID $HOME_DIR
        ls -la $HOME_DIR -d
        ls -la $HOME_DIR
        if [ -n "${AUDIO_GID}" ]; then
            create_audio_gid
        fi
        chown -R $USER_NAME:$GROUP_NAME /config
        chown -R $USER_NAME:$GROUP_NAME /cache
        chown -R $USER_NAME:$GROUP_NAME /data
    else 
        echo "User mode disabled"
    fi
fi

COMMAND_LINE="PYTHONPATH=/opt/mopidy-venv mopidy"

# config dir
CONFIG_DIR=/config
if [ ! -w $CONFIG_DIR ]; then
    echo "Cache directory [${CONFIG_DIR}] is not writable"
    CONFIG_DIR="/tmp/$CONFIG_DIR"
    mkdir -p $CONFIG_DIR
else
    echo "Config directory [${CONFIG_DIR}] is writable"
fi

echo "Removing configuration files ..."
rm $CONFIG_DIR/*conf
echo ". done"

# cache dir
CACHE_DIR=/cache
if [ ! -w $CACHE_DIR ]; then
    echo "Cache directory [${CACHE_DIR}] is not writable"
    CACHE_DIR="/tmp/$CACHE_DIR"
    mkdir -p $CACHE_DIR
else
    echo "Cache directory [${CACHE_DIR}] is writable"
fi
#COMMAND_LINE="$COMMAND_LINE --option core/cache_dir=${CACHE_DIR}"

# data dir
DATA_DIR=/data
if [ ! -w $DATA_DIR ]; then
    echo "Data directory [${DATA_DIR}] is not writable"
    DATA_DIR="/tmp/$DATA_DIR"
    mkdir -p $DATA_DIR
else
    echo "Data directory [${DATA_DIR}] is writable"
fi
#COMMAND_LINE="$COMMAND_LINE --option core/data_dir=${DATA_DIR}"

echo "[core]" > $CONFIG_DIR/mopidy.conf
echo "cache_dir = $CACHE_DIR" >> $CONFIG_DIR/mopidy.conf
echo "config_dir = $CONFIG_DIR" >> $CONFIG_DIR/mopidy.conf
echo "data_dir = $DATA_DIR" >> $CONFIG_DIR/mopidy.conf

if [[ -n "${RESTORE_STATE}" ]]; then
    if [[ "${RESTORE_STATE^^}" == "YES" ]] || [[ "${RESTORE_STATE^^}" == "Y" ]]; then
        echo "restore_state = true" >> $CONFIG_DIR/mopidy.conf
    elif [[ "${RESTORE_STATE^^}" != "NO" ]] && [[ "${RESTORE_STATE^^}" != "N" ]]; then
        echo "Invalid RESTORE_STATE=[$RESTORE_STATE]"
        exit 1
    fi
fi

LOG_SWITCH=""
if [[ -n "${LOG_LEVEL}" ]]; then
    if [[ "$LOG_LEVEL" -eq 0 ]]; then
        LOG_SWITCH="-q"
    elif [[ "$LOG_LEVEL" -eq 1 ]]; then
        LOG_SWITCH=""
    elif [[ "$LOG_LEVEL" -eq 2 ]]; then
        LOG_SWITCH="-v"
    else
        echo "Invalid LOG_LEVEL=[$LOG_LEVEL]"
        exit 1
    fi
fi

COMMAND_LINE="$COMMAND_LINE $LOG_SWITCH --config $CONFIG_DIR --option core/cache_dir=${CACHE_DIR} --option core/data_dir=${DATA_DIR}"

# IRIS web gui
echo "[iris]" > $CONFIG_DIR/iris.conf
echo "enabled = true" >> $CONFIG_DIR/iris.conf
echo "data_dir = $DATA_DIR/iris" >> $CONFIG_DIR/iris.conf

# HTTP
echo "[http]" > $CONFIG_DIR/http.conf
echo "enabled = true" >> $CONFIG_DIR/http.conf
echo "hostname = 0.0.0.0" >> $CONFIG_DIR/http.conf
echo "port = 6680" >> $CONFIG_DIR/http.conf

if [[ -n "${AUDIO_OUTPUT}" ]]; then
    #COMMAND_LINE="$COMMAND_LINE --option audio/output=\"${AUDIO_OUTPUT}\""
    echo "[audio]" > $CONFIG_DIR/audio.conf
    echo "output = ${AUDIO_OUTPUT}" >> $CONFIG_DIR/audio.conf
fi

ENABLE_JELLYFIN=0
if [[ -z "${JELLYFIN_ENABLED}" ]]; then
    ENABLE_JELLYFIN=0
else
    if [[ "${JELLYFIN_ENABLED^^}" == "YES" ]] || [[ "${JELLYFIN_ENABLED^^}" == "Y" ]]; then
        ENABLE_JELLYFIN=1
    elif [[ "${JELLYFIN_ENABLED^^}" != "NO" ]] && [[ "${JELLYFIN_ENABLED^^}" != "N" ]]; then
        echo "Invalid JELLYFIN_ENABLED=[$JELLYFIN_ENABLED]"
        exit 1
    fi
fi

if [[ $ENABLE_JELLYFIN -eq 1 ]]; then
    echo "[jellyfin]" > $CONFIG_DIR/jellyfin.conf
    echo "enabled = true" >> $CONFIG_DIR/jellyfin.conf

    if [[ -n "${JELLYFIN_HOSTNAME}" ]]; then
        echo "hostname = ${JELLYFIN_HOSTNAME}" >> $CONFIG_DIR/jellyfin.conf
    else
        echo "Hostname not specified for Jellyfin plugin!"
        exit 1
    fi
    if [[ -n "${JELLYFIN_USERNAME}" ]]; then
        echo "username = ${JELLYFIN_USERNAME}" >> $CONFIG_DIR/jellyfin.conf
    else
        echo "Username not specified for Jellyfin plugin!"
    fi
    if [[ -n "${JELLYFIN_PASSWORD}" ]]; then
        echo "password = ${JELLYFIN_PASSWORD}" >> $CONFIG_DIR/jellyfin.conf
    else
        echo "Password not specified for Jellyfin plugin!"
    fi
    if [[ -n "${JELLYFIN_USER_ID}" ]]; then
        echo "user_id = ${JELLYFIN_USER_ID}" >> $CONFIG_DIR/jellyfin.conf
    else
        echo "User id not specified for Jellyfin plugin!"
    fi
    if [[ -n "${JELLYFIN_TOKEN}" ]]; then
        echo "token = ${JELLYFIN_TOKEN}" >> $CONFIG_DIR/jellyfin.conf
    else
        echo "Token not specified for Jellyfin plugin!"
    fi
    if [[ -n "${JELLYFIN_LIBRARIES}" ]]; then
        echo "libraries = ${JELLYFIN_LIBRARIES}" >> $CONFIG_DIR/jellyfin.conf
    else
        echo "Libraries not specified for Jellyfin plugin, will use the default ""Music"""
    fi
    if [[ -n "${JELLYFIN_ALBUM_ARTIST_SORT}" ]]; then
        echo "albumartistsort = ${JELLYFIN_ALBUM_ARTIST_SORT}" >> $CONFIG_DIR/jellyfin.conf
    fi
    if [[ -n "${JELLYFIN_ALBUM_FORMAT}" ]]; then
        echo "album_format = ${JELLYFIN_ALBUM_FORMAT}" >> $CONFIG_DIR/jellyfin.conf
    fi
    if [[ -n "${JELLYFIN_MAX_BITRATE}" ]]; then
        echo "max_bitrate = ${JELLYFIN_MAX_BITRATE}" >> $CONFIG_DIR/jellyfin.conf
    fi
fi

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
    if [[ -n "${TIDAL_LOGIN_METHOD}" ]]; then
        echo "login_method = ${TIDAL_LOGIN_METHOD}" >> $CONFIG_DIR/tidal.conf
    fi
    if [[ -n "${TIDAL_AUTH_METHOD}" ]]; then
        echo "auth_method = ${TIDAL_AUTH_METHOD}" >> $CONFIG_DIR/tidal.conf
    fi
    if [[ -n "${TIDAL_LOGIN_SERVER_PORT}" ]]; then
        echo "login_server_port = ${TIDAL_LOGIN_SERVER_PORT}" >> $CONFIG_DIR/tidal.conf
    fi
    if [[ -n "${TIDAL_PLAYLIST_CACHE_REFRESH_SECS}" ]]; then
        echo "playlist_cache_refresh_secs = ${TIDAL_PLAYLIST_CACHE_REFRESH_SECS}" >> $CONFIG_DIR/tidal.conf
    fi
    if [[ -n "${TIDAL_LAZY}" ]]; then
        echo "lazy = ${TIDAL_LAZY}" >> $CONFIG_DIR/tidal.conf
    fi
else
    echo "[tidal]" > $CONFIG_DIR/tidal.conf
    echo "enabled = false" >> $CONFIG_DIR/tidal.conf
fi

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

ENABLE_FILE=0
if [[ -z "${FILE_ENABLED}" ]]; then
    ENABLE_FILE=0
else
    if [[ "${FILE_ENABLED^^}" == "YES" ]] || [[ "${FILE_ENABLED^^}" == "Y" ]]; then
        ENABLE_FILE=1
    elif [[ "${FILE_ENABLED^^}" != "NO" ]] && [[ "${FILE_ENABLED^^}" != "N" ]]; then
        echo "Invalid FILE_ENABLED=[$FILE_ENABLED]"
        exit 1
    fi
fi

if [[ $ENABLE_FILE -eq 1 ]]; then
    echo "[file]" > $CONFIG_DIR/file.conf
    echo "enabled = true" >> $CONFIG_DIR/file.conf
    echo "media_dirs = /music" >> $CONFIG_DIR/file.conf
else
    echo "[file]" > $CONFIG_DIR/file.conf
    echo "enabled = false" >> $CONFIG_DIR/file.conf
fi

ENABLE_LOCAL=0
if [[ -z "${LOCAL_ENABLED}" ]]; then
    ENABLE_LOCAL=0
else
    if [[ "${LOCAL_ENABLED^^}" == "YES" ]] || [[ "${LOCAL_ENABLED^^}" == "Y" ]]; then
        ENABLE_LOCAL=1
    elif [[ "${LOCAL_ENABLED^^}" != "NO" ]] && [[ "${LOCAL_ENABLED^^}" != "N" ]]; then
        echo "Invalid LOCAL_ENABLED=[$LOCAL_ENABLED]"
        exit 1
    fi
fi

if [[ $ENABLE_LOCAL -eq 1 ]]; then
    echo "[local]" > $CONFIG_DIR/local.conf
    echo "enabled = true" >> $CONFIG_DIR/local.conf
    echo "media_dir = /music" >> $CONFIG_DIR/local.conf
else
    echo "[local]" > $CONFIG_DIR/local.conf
    echo "enabled = false" >> $CONFIG_DIR/local.conf
fi

ENABLE_MPD=0
if [[ -z "${MPD_ENABLED}" ]]; then
    ENABLE_MPD=0
else
    if [[ "${MPD_ENABLED^^}" == "YES" ]] || [[ "${MPD_ENABLED^^}" == "Y" ]]; then
        ENABLE_MPD=1
    elif [[ "${MPD_ENABLED^^}" != "NO" ]] && [[ "${MPD_ENABLED^^}" != "N" ]]; then
        echo "Invalid MPD_ENABLED=[$MPD_ENABLED]"
        exit 1
    fi
fi

if [[ $ENABLE_MPD -eq 1 ]]; then
    echo "[mpd]" > $CONFIG_DIR/mpd.conf
    echo "enabled = true" >> $CONFIG_DIR/mpd.conf
    echo "hostname = 0.0.0.0" >> $CONFIG_DIR/mpd.conf
else
    echo "[mpd]" > $CONFIG_DIR/mpd.conf
    echo "enabled = false" >> $CONFIG_DIR/mpd.conf
fi

ENABLE_MOBILE=0
if [[ -z "${MOBILE_ENABLED}" ]]; then
    ENABLE_MOBILE=0
else
    if [[ "${MOBILE_ENABLED^^}" == "YES" ]] || [[ "${MOBILE_ENABLED^^}" == "Y" ]]; then
        ENABLE_MOBILE=1
    elif [[ "${MOBILE_ENABLED^^}" != "NO" ]] && [[ "${MOBILE_ENABLED^^}" != "N" ]]; then
        echo "Invalid MOBILE_ENABLED=[$MOBILE_ENABLED]"
        exit 1
    fi
fi

if [[ $ENABLE_MOBILE -eq 1 ]]; then
    echo "[mobile]" > $CONFIG_DIR/mobile.conf
    echo "enabled = true" >> $CONFIG_DIR/mobile.conf
    if [[ -n "${MOBILE_TITLE}" ]]; then
        echo "title = ${MOBILE_TITLE}" >> $CONFIG_DIR/mobile.conf
    fi
    if [[ -n "${MOBILE_WS_URL}" ]]; then
        echo "ws_url = ${MOBILE_WS_URL}" >> $CONFIG_DIR/mobile.conf
    fi
else
    echo "[mobile]" > $CONFIG_DIR/mobile.conf
    echo "enabled = false" >> $CONFIG_DIR/mobile.conf
fi


echo "COMMAND_LINE=[${COMMAND_LINE}]"

echo "Configuration: "
CONFIG_COMMAND_LINE="mopidy --config $CONFIG_DIR config"
eval $CONFIG_COMMAND_LINE

echo "CMD_LINE=[$CMD_LINE]"
if [[ $current_user_id -eq 0 ]]; then
    echo "Container running as root"
    if [[ $USE_USER_MODE == "Y" ]]; then
        echo "User mode enabled"
        su - $USER_NAME -c "$COMMAND_LINE"
    else
        echo "user mode not enabled"
        eval "$COMMAND_LINE"
    fi
else
    echo "Container running as ${current_user_id}"
    eval "$COMMAND_LINE"
fi

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

if [[ "${current_user_id}" == "0" && (! (${USER_MODE^^} == "NO" || ${USER_MODE^^} == "N")) ]]; then
    if [[ "${USER_MODE^^}" == "YES" || "${USER_MODE^^}" == "Y" ]]; then
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

COMMAND_LINE="$COMMAND_LINE --config $CONFIG_DIR --option core/cache_dir=${CACHE_DIR} --option core/data_dir=${DATA_DIR}"

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

/app/bin/tidal.sh
/app/bin/spotify.sh
/app/bin/scrobbler.sh

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

echo "COMMAND_LINE=[${COMMAND_LINE}]"

echo "Configuration: "
CONFIG_COMMAND_LINE="mopidy --config $CONFIG_DIR config"
eval $CONFIG_COMMAND_LINE

echo "CMD_LINE=[$CMD_LINE]"
if [[ $current_user_id -eq 0 ]]; then
    echo "Container running as root"
    if [ $USE_USER_MODE == "Y" ]; then
        echo "User mode enabled"
        su - $USER_NAME -c "$CMD_LINE"
    else
        echo "user mode not enabled"
        eval "$COMMAND_LINE"
    fi
else
    echo "Container running as ${current_user_id}"
    eval "$COMMAND_LINE"
fi

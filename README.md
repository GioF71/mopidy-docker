# mopidy-docker

Run Mopidy in Docker

## Description

I wanted to be able to play from Tidal to my audio devices (typically Raspberry Pi SBC), directly from a browser, without using Tidal Connect, not available on any device/platform.  
[Mopidy](https://mopidy.com/) along with the [Mopidy-Tidal plugin](https://github.com/tehkillerbee/mopidy-tidal) offer a very nice interface, and represent a good response to this requirement.  
I have only used it with alsa output, but I will probably add support for PulseAudio soon. Note that this is not terribly important to me, at least when using Tidal, which my main scenario.  Using this application with PulseAudio would not offer any particular advantage compared to the Tidal Web Player.  

## References

PROJECT|URL
:---|:---
Mopidy|[Main site](https://mopidy.com/)
python-tidal|[GitHub repo](https://github.com/tamland/python-tidal)
mopidy-tidal|[GitHub repo](https://github.com/tehkillerbee/mopidy-tidal)

## Build

In order to build the docker image, switch to the root directory of the repo and use the following command:

`./local-build.sh`

I will publish pre-built images as soon as possible.  

## Configuration

The configuration if driven by environment variables. You should not need to edit the configuration files directly.  

### Variables

VARIABLE|DESCRIPTION
:---|:---
AUDIO_OUTPUT|Audio output configuration
RESTORE_STATE|Restore last state on start, defaults to `no`
TIDAL_ENABLED|Enables the Tidal plugin, defaults to `no`
TIDAL_QUALITY|Set quality for the Tidal plugin, defaults to `LOSSLESS`
FILE_ENABLED|Enables the File plugin, defaults to `no`
LOCAL_ENABLED|Enables the Local plugin, defaults to `no`
SCROBBLER_ENABLED|Enables the Scrobbler plugin, defaults to `no`
SCROBBLER_USERNAME|Last.FM username
SCROBBLER_PASSWORD|Last.FM password
USER_MODE|Set to `yes` to enable user mode
PUID|The uid for `USER_MODE`, defaults to `1000`
PGID|The gid for `USER_MODE`, defaults to `1000`
AUDIO_GID|Group id for `USER_MODE`, set it to the group id of the group `audio` if `USER_MODE` is enabled

### Volumes

VOLUME|DESCRIPTION
:---|:---
/config|Configuration directory
/data|Data directory
/cache|Cache directory
/music|Music directory

## Examples

A simple docker-compose.yaml file.  
Please note that this assumes your user of choice has uid `1000` and that the audio gid is `29`.  
Also the selected audio output is the alsa device named `D10` (a Topping D10).  
The Tidal plugin is enabled with LOSSLESS quality.  

```text
---
version: "3.3"

services:
  mopidy:
    image: giof71/mopidy
    container_name: mopidy
    user: "1000:29"
    devices:
      - /dev/snd:/dev/snd
    environment:
      - AUDIO_OUTPUT=alsasink device=hw:D10
      - RESTORE_STATE=yes
      - SCROBBLER_ENABLED=${SCROBBLER_ENABLED:-no}
      - SCROBBLER_USERNAME=${SCROBBLER_USERNAME}
      - SCROBBLER_PASSWORD=${SCROBBLER_PASSWORD}
      - TIDAL_ENABLED=yes
      - TIDAL_QUALITY=LOSSLESS
    ports:
      - 6680:6680
    volumes:
      - ./config:/config
      - ./cache:/cache
      - ./data:/data
    restart: always
```

In order to correctly set the credentials for Tidal, the first run should be done with this command:

`docker-compose run mopidy`

Look at the displayed instructions, follow the link and authorize the application on Tidal.  
You will need an active Tidal subscription, of course.  
After this action, you can stop the container (CTRL-C), and then start it normally using:

`docker-compose up -d`

The application should be accessible at the host-ip at port 6680.  

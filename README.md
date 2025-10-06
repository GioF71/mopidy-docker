# mopidy-docker

Run Mopidy in Docker

## Description

I wanted to be able to play from Tidal to my audio devices (typically Raspberry Pi SBCs), directly from a browser, without using Tidal Connect, not available on any device/platform.  
[Mopidy](https://mopidy.com/) along with the [Mopidy-Tidal plugin](https://github.com/tehkillerbee/mopidy-tidal) offer a very nice interface, and represent a good response to this requirement.  
Also, I like Mopidy to be able to connect to [Jellyfin](https://jellyfin.org/) for music playback, as I am starting to explore this option.  
I have only used it with alsa output, but I will probably add support for PulseAudio soon. Note that this is not terribly important to me, at least when using Tidal, which my main scenario.  Using this application with PulseAudio would not offer any particular advantage compared to the Tidal Web Player.  

## Support

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/H2H7UIN5D)  
Please see the [Goal](https://ko-fi.com/giof71/goal?g=0).  
Please note that support goal is limited to cover running costs for subscriptions to music services.

## References

PROJECT|URL
:---|:---
Mopidy|[Main site](https://mopidy.com/)
mopidy-tidal|[GitHub repo](https://github.com/tehkillerbee/mopidy-tidal)
python-tidal|[GitHub repo](https://github.com/tamland/python-tidal)
mopidy-jellyfin|[GitHub repo](https://github.com/jellyfin/mopidy-jellyfin)
mopidy-mobile|[GitHub repo](https://github.com/tkem/mopidy-mobile)

## Repositories

Repo Type|Link
:---|:---
Source Code|[GitHub](https://github.com/giof71/mopidy-docker)  
Docker Images|[Docker Hub](https://hub.docker.com/r/giof71/mopidy)

## Contributors

Contributor|PRs
:---|:---
[peterzen](https://github.com/peterzen)|[#6](https://github.com/GioF71/mopidy-docker/pull/6) [#7](https://github.com/GioF71/mopidy-docker/pull/7) [#10](https://github.com/GioF71/mopidy-docker/pull/10)

## Build

If, for any reason, you don't want or cannot use the images I publish to the [Docker Hub Repository](https://hub.docker.com/r/giof71/mopidy), you can build the image locally by switching to the root directory of the repository and issuing the following command:

`./local-build.sh`

## Configuration

The configuration if driven by environment variables. You should not need to edit the configuration files directly.  

### Variables

VARIABLE|DESCRIPTION
:---|:---
AUDIO_OUTPUT|Audio output configuration
RESTORE_STATE|Restore last state on start, defaults to `no`
TIDAL_ENABLED|Enables the Tidal plugin, defaults to `no`
TIDAL_QUALITY|Set quality for the Tidal plugin, defaults to `LOSSLESS`
TIDAL_LOGIN_METHOD|Login method, can be `BLOCK` (default), `AUTO` or `HACK`
TIDAL_AUTH_METHOD|Authentication method, can be `OAUTH` (default) or `PKCE` (legacy)
TIDAL_PLAYLIST_CACHE_REFRESH_SECS|Playlist content refresh time, defaults to `0`
TIDAL_LOGIN_SERVER_PORT|Required for PKCE authentication, should not be mandatory for hires anymore.
TIDAL_LAZY|Lazy connection, `true` or `false` (default)
JELLYFIN_ENABLED|Enables the Jellyfin plugin, defaults to `no`
JELLYFIN_HOSTNAME|Hostname for Jellyfin (mandatory)
JELLYFIN_USERNAME|Username for Jellyfin
JELLYFIN_PASSWORD|Password for Jellyfin
JELLYFIN_USER_ID|User Id for Jellyfin
JELLYFIN_TOKEN|Token for Jellyfin
JELLYFIN_LIBRARIES|Libraries for Jellyfin (optional, defaults to `Music`)
JELLYFIN_ALBUM_ARTIST_SORT|Optional, defaults to `false`
JELLYFIN_ALBUM_FORMAT|Optional, will default to `"{Name}"`
JELLYFIN_MAX_BITRATE|Optional, numeric
FILE_ENABLED|Enables the File plugin, defaults to `no`
LOCAL_ENABLED|Enables the Local plugin, defaults to `no`
LOCAL_MEDIA_DIR|Path to local music directory, defaults to `/music`
LOCAL_MAX_SEARCH_RESULTS|Number of search results to return, defaults to `100`
LOCAL_SCAN_TIMEOUT|Milliseconds before giving up scanning a file
LOCAL_SCAN_FOLLOW_SYMLINKS|Whether to follow symlinks, `yes` or `no`
LOCAL_SCAN_FLUSH_THRESHOLD|Number of tracks before flushing progress, `0` to disable
LOCAL_INCLUDED_FILE_EXTENSIONS|File extensions to include (comma separated, e.g. `.flac,.mp3`)
LOCAL_EXCLUDED_FILE_EXTENSIONS|File extensions to exclude (comma separated, e.g. `.txt`)
LOCAL_DIRECTORIES|List of top-level directory names and URIs for browsing
LOCAL_TIMEOUT|Database connection timeout in seconds
LOCAL_USE_ARTIST_SORTNAME|Use sortname field for ordering artist browse results, `yes` or `no`
LOCAL_ALBUM_ART_FILES|List of file names to check for album art (comma or newline separated)
SCROBBLER_ENABLED|Enables the Scrobbler plugin, defaults to `no`
SCROBBLER_USERNAME|Last.FM username
SCROBBLER_PASSWORD|Last.FM password
MPD_ENABLED|Enables the MPD plugin, defaults to `no`
MOBILE_ENABLED|Set to `yes` to enable mobile UI
MOBILE_TITLE|Web application's title, defaults to `Mopidy Mobile on $hostname`
MOBILE_WS_URL|WebSocket URL used to connect to your Mopidy server, set this when using a reverse proxy
USER_MODE|Set to `yes` to enable user mode
PUID|The uid for `USER_MODE`, defaults to `1000`
PGID|The gid for `USER_MODE`, defaults to `1000`
AUDIO_GID|Group id for `USER_MODE`, set it to the group id of the group `audio` if `USER_MODE` is enabled
LOG_LEVEL|0: quiet, 1: default, 2: verbose

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
The audio gid is generally `29` for debian base distros, including Moode Audio.  
Also the selected audio output is the alsa device named `D10` (matches the card name of a Topping D10).  
The Tidal plugin is enabled with LOSSLESS quality.  
Make sure you create the `config`, `cache` and `data` directories where you place this `docker-compose.yaml` file, and that those directories are writable for the user identified by the uid (`1000` in the example) and gid (`29` in the example) that you choose.  

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
      - SCROBBLER_ENABLED=${SCROBBLER_ENABLED:-}
      - SCROBBLER_USERNAME=${SCROBBLER_USERNAME:-}
      - SCROBBLER_PASSWORD=${SCROBBLER_PASSWORD:-}
      - TIDAL_ENABLED=yes
      - TIDAL_QUALITY=${TIDAL_QUALITY:-LOSSLESS}
    ports:
      - 6680:6680
      - 8989:8989
    volumes:
      - ./config:/config
      - ./cache:/cache
      - ./data:/data
    restart: always
```

In order to correctly set the credentials for Tidal, the first run should be done with this command:

`docker-compose run mopidy`

Look at the displayed instructions. The log should present a line similar to the following:

```text
mopidy-app | INFO     2024-11-17 11:37:31,306 [39:TidalBackend-7 (_actor_loop)] mopidy_tidal.backend
mopidy-app |   Please visit 'http://localhost:8989' or 'https://link.tidal.com/XXXXX' to authenticate
```

follow the second link, authenticate with Tidal (if necessary) and authorize the new device on Tidal.  
If, for any reason, you want to use the `PKCE` authentication, use the first link and follow the instructions that will be presented.  

You will need an active Tidal subscription, of course.  
After this action, you can stop the container (CTRL-C), and then start it normally using:

`docker-compose up -d`

The application should be accessible at the host-ip at port 6680.  

## Change History

Change Data|Major Changes
:---|:---
2025-09-14|Rebuild with version [v0.3.11](https://github.com/tehkillerbee/mopidy-tidal/releases/tag/v0.3.11)
2025-07-12|Rebuild with version [v0.3.10](https://github.com/tehkillerbee/mopidy-tidal/releases/tag/v0.3.10)
2024-11-13|Rebuild with version [v0.3.9](https://github.com/tehkillerbee/mopidy-tidal/releases/tag/v0.3.9)
2024-11-10|Rebuild with version [v0.3.8](https://github.com/tehkillerbee/mopidy-tidal/releases/tag/v0.3.8)
2024-09-08|Add support for the jellyfin plugin
2024-09-05|Fixed user management
2024-09-05|Switch to ubuntu noble
2024-05-22|Enable user mode if PUID is set
2024-05-22|Add support for user mode
2024-03-04|Add configuration options
2024-03-03|Add pkce support for Tidal plugin
2024-02-22|Add support for the MPD plugin
2024-02-21|Review build process
2024-02-21|First working version

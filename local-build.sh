#!/bin/bash

docker build . -t giof71/mopidy:latest --progress=plain "$@"

#!/bin/bash

docker build . -t giof71/mopidy:local --progress=plain "$@"

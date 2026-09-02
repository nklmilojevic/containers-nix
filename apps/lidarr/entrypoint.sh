#!/usr/bin/env bash

exec \
    Lidarr \
        --nobrowser \
        --data=/config \
        "$@"

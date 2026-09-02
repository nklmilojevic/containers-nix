#!/usr/bin/env bash

exec \
    Radarr \
        --nobrowser \
        --data=/config \
        "$@"

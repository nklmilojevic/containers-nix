#!/usr/bin/env bash

exec \
    Sonarr \
       --nobrowser \
       --data=/config \
       "$@"

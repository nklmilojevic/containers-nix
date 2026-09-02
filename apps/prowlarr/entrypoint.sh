#!/usr/bin/env bash

exec \
    Prowlarr \
       --nobrowser \
       --data=/config \
       "$@"

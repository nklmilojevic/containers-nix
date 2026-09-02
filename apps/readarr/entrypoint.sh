#!/usr/bin/env bash

exec \
    Readarr \
       --nobrowser \
       --data=/config \
       "$@"

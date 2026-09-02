#!/usr/bin/env bash

exec \
    tautulli \
        --nolaunch \
        --config /config/config.ini \
        --datadir /config \
        "$@"

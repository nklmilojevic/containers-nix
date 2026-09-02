#!/usr/bin/env bash

exec \
    bazarr \
        --no-update True \
        --config /config \
        --port "${BAZARR__PORT}" \
        "$@"

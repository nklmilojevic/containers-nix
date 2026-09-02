#!/usr/bin/env bash

CONFIG_FILE="/config/qBittorrent/qBittorrent.conf"
LOG_FILE="/config/qBittorrent/logs/qbittorrent.log"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    mkdir -p "${CONFIG_FILE%/*}"
    cp /defaults/qBittorrent.conf "${CONFIG_FILE}"
fi

if [[ ! -f "${LOG_FILE}" ]]; then
    mkdir -p "${LOG_FILE%/*}"
    ln -sf /proc/self/fd/1 "${LOG_FILE}"
fi

exec qbittorrent-nox "$@"

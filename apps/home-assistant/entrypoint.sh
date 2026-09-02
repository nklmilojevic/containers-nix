#!/usr/bin/env bash

# --skip-pip: dependency versions come from nixpkgs and may differ from the
# exact pins in Home Assistant's manifests; without the flag Home Assistant
# tries to pip-install the pinned versions at startup and aborts when that
# fails. This also means custom components cannot install their requirements
# at runtime; they have to be added to the image.
ln -sf /proc/self/fd/1 /config/home-assistant.log

exec \
    @python@ -m homeassistant \
        --config /config \
        --skip-pip \
        "$@"

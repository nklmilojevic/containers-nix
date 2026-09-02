#!/usr/bin/env bash
# Refresh apps/<app>/hashes.json from the URLs declared in the app's `sources`.
# Usage: scripts/update-hashes.sh <app> [<app>...]
set -euo pipefail

cd "$(dirname "$0")/.."
flake="${FLAKE_REF:-.}"

for app in "$@"; do
    out="apps/${app}/hashes.json"
    sources=$(nix eval --json "${flake}#meta.${app}.sources")
    result='{}'
    while IFS=$'\t' read -r name system url; do
        echo "[${app}] ${name} ${system}" >&2
        hash=$(nix store prefetch-file --json "${url}" | jq -r .hash)
        result=$(jq --arg n "${name}" --arg s "${system}" --arg h "${hash}" '.[$n][$s] = $h' <<<"${result}")
    done < <(jq -r 'to_entries[] | .key as $n | .value.urls | to_entries[] | [$n, .key, .value] | @tsv' <<<"${sources}")
    jq -S . <<<"${result}" > "${out}"
    echo "[${app}] wrote ${out}" >&2
done

#!/usr/bin/env bash
# Backwards-compatible alias — runs scripts/local.sh
exec "$(dirname "$0")/local.sh" "$@"

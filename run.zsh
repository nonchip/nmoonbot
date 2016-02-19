#!/bin/zsh
cd "$(dirname "$(readlink -f "$0")")"

lib/nMoonLib/moon init.moon "$@"

#!/bin/zsh

git submodule init
git submodule update
lib/nMoonLib/setup.zsh
lib/nMoonLib/.run luarocks install lanes
lib/nMoonLib/.run luarocks install luasocket

#!/usr/bin/env bash
source ./.env

if [ -d "tmp"  ]; then
    rm -rf tmp
fi

mkdir tmp

git clone https://github.com/JSbenchOrg/client tmp/client
git clone https://github.com/JSbenchOrg/server tmp/server

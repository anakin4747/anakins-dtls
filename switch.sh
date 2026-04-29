#!/usr/bin/env bash
set -e

git pull

nix profile remove anakins-dtls
echo REMOVED

nix profile add .
echo ADDED

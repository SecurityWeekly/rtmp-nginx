#!/usr/bin/env bash

docker-compose down --rmi all --remove-orphans
docker-compose build --force-rm --no-cache --pull --parallel
docker-compose up -d

#!/bin/sh

docker build --no-cache -t webapp-simple-image .
docker save -o webapp-simple.zip webapp-simple-image


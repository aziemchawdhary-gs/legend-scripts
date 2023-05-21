#!/bin/bash

git diff --name-only HEAD master -- . | cut -d/ -f1 | xargs mvn clean install -DskipTests -T2 -pl "$@" "$@"

#!/bin/bash

for file in ./*.dockerfile; do
  name=$(echo "`basename "$file"`" | cut -f 1 -d '.')
  echo "Building $name..."
  DOCKER_BUILDKIT=0 docker build -q -t $name:logicboard -f $file .
done
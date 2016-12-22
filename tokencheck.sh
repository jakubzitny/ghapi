#!/bin/bash

for i in `cat toks`
do
  curl --silent "https://api.github.com/rate_limit?access_token=$i" -H 'Accept: application/vnd.github.preview' | jq '.resources.core.remaining'
  echo $i
  echo "===="
done

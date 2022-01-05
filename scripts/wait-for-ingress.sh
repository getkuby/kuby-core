#! /bin/bash

while true; do
  nc -z -v localhost 5555
  if [[ $? == 0 ]]; then
    break
  fi
  echo 'Waiting for ingress port forwarding...'
  sleep 1
done

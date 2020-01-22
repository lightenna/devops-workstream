#!/usr/bin/env bash

## change directory to this script's dir
cd $(dirname "$0")

# destroy in parallel
INDEX=0
for i in */
do
  echo "Destroying ${i}"
  cd $i
  vagrant destroy -f &
  # track PID of background task
  PID[$INDEX]=$!
  cd ..
  INDEX=$INDEX+1
done

# test once all VMs become available
INDEX=0
for i in */
do
  echo "Waiting for ${i} to be destroyed"
  wait ${PID[$INDEX]}
  INDEX=$INDEX+1
done

echo "All done"
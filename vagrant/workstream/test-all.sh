#!/usr/bin/env bash

## change directory to this script's dir
cd $(dirname "$0")

## initialise output file
abs_output="$(pwd)/output.txt"
echo "Test run started $(date)" > $abs_output

provision=1

## provision in parallel
if [[ "$provision" -eq 1 ]]; then
  INDEX=0
  for i in */
  do
    echo "Provisioning ${i}" >> $abs_output
    echo "Provisioning ${i}"
    cd $i
    # provision using vagrant in background
    vagrant up --provision &
    # track PID of background task
    PID[$INDEX]=$!
    cd ..
    INDEX=$INDEX+1
  done
fi

# test once all VMs become available
INDEX=0
for i in */
do
  if [[ "$provision" -eq 1 ]]; then
    echo "Waiting for ${i} to be ready"
    wait ${PID[$INDEX]}
  fi
  echo "Testing ${i}"
  cd $i
  # run rspec using vagrant and capture output
  rspec_output=`vagrant ssh -c 'rspec --no-color --format documentation /srv/selftest/selftest.rb'`
  # test result of test
  if [ $? -eq 0 ]; then
      echo "Tested ${i}: OK" >> $abs_output
  else
      echo "Tested ${i}: FAIL" >> $abs_output
      echo "Rspec report: ${rspec_output}" >> $abs_output
      echo "---" >> $abs_output
  fi
  cd ..
  INDEX=$INDEX+1
done

echo "Test run completed $(date)" >> $abs_output

cat $abs_output
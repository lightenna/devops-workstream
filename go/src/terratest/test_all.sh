#!/usr/bin/env bash
source ./set_environment_variables.sh
cd "$(dirname "$0")"
go test -v -timeout 90m . > test_cmd.out &
tail -n1000 -f test_cmd.out

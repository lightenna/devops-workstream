#!/usr/bin/env bash
# generic test runner v1.0
# best run in background with:
#   bash -c './run_test_suite.sh &' ; tail -f -n100 test_cmd.out
export GOPATH=$(dirname $(dirname $(dirname $(readlink -f "$0"))))
echo "GOPATH=${GOPATH}"
cd "$(dirname $(readlink -f "$0"))"
# run `dep ensure` everytime, but will only fetch and cache deps on first run
dep ensure
raw_log="test_cmd.out"
output_folder_path="./test_output"
output_summary="summary.log"
go test -count=1 -v -timeout 90m ./test > "${raw_log}"
# when the test run finishes, split up the test output
terratest_log_parser -testlog "${raw_log}" -outputdir "${output_folder_path}"
# gather data on tests run
test_date=$(stat -c %y "${raw_log}")
branch=$(git branch)
commit_hash=$(git rev-parse HEAD)
commit_detail=$(git log --no-walk --pretty=fuller "${commit_hash}")
printf "\nTested ${branch}\n" >> "${output_folder_path}/${output_summary}"
printf "${commit_detail}\n\n" >> "${output_folder_path}/${output_summary}"
printf "Completed (${test_date})\n" >> "${output_folder_path}/${output_summary}"
cat "${output_folder_path}/${output_summary}"

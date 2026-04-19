#!/usr/bin/env bash
set -Eeuo pipefail
function quality(){
echo "Quality Passed"
}
test_quality1(){
echo "Qsuality 1 Passed"
}
main(){
echo "Hello World"
}
declare -ag ___APP_TESTS_LIST___=(
quality
test_quality1)
declare -Ag ___APP_TEST_MAP___=(
[quality]=quality
[test_quality1]=test_quality1
[quality1]=test_quality1)
___app_resolve_test___(){
local want="${1:-}"
[[ -n $want ]]||return 1
[[ -n ${___APP_TEST_MAP___[$want]:-} ]]||return 1
printf '%s\n' "${___APP_TEST_MAP___[$want]}"
}
___app_run_tests___(){
local fn="" rc=0 pass=0 fail=0
local -a tests=("$@")
for fn in "${tests[@]}";do
printf '==> %s\n' "$fn"
if "$fn" 2>/dev/null;then
printf '[PASS]: %s\n' "$fn"
((++pass))
else
printf '[FAIL]: %s\n' "$fn" >&2
((++fail))
rc=1
fi
printf '\n'
done
printf '[INFO]: total=%s pass=%s fail=%s\n' "${#tests[@]}" "$pass" "$fail"
return "$rc"
}
___app_test___(){
local target="" resolved=""
if (($#==0));then
___app_run_tests___ "${___APP_TESTS_LIST___[@]}"
return $?
fi
target="${1:-}"
shift||true
if ! resolved="$(___app_resolve_test___ "$target" 2>/dev/null)";then
printf '[FAIL]: test not found: %s\n' "$target" >&2
printf '[INFO]: total=1 pass=0 fail=1\n' >&2
return 1
fi
printf '==> %s\n' "$resolved"
if "$resolved" "$@" 2>/dev/null;then
printf '[PASS]: %s\n\n' "$resolved"
printf '[INFO]: total=1 pass=1 fail=0\n'
return 0
fi
printf '[FAIL]: %s\n\n' "$resolved" >&2
printf '[INFO]: total=1 pass=0 fail=1\n' >&2
return 1
}
___app_tests___(){
local fn=""
for fn in "${___APP_TESTS_LIST___[@]}";do
printf '%s\n' "$fn"
done
}
readonly ___APP_SRC_CHECKSUM___='70871ac7bc6b6f90cfc896ce5746c9571ca34696ebdbf0adb3489fa2fcf7bee7'
___app_main___(){
main "$@"
}
___app_start___(){
local cmd="${1:-}"
shift||true
case "$cmd" in
--test)___app_test___ "$@";;
--tests)___app_tests___ "$@";;
*)___app_main___ "$@"
esac
}
___app_start___ "$@"
exit $?

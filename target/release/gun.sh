#!/usr/bin/env bash
set -Eeuo pipefail
__file_marker__(){
return 0
}
__trace_trim__(){
local s="${1-}"
s="${s#"${s%%[![:space:]]*}"}"
s="${s%"${s##*[![:space:]]}"}"
printf '%s\n' "$s"
}
__trace_get_line__(){
local file="${1:-}" line="${2:-0}"
[[ -f $file ]]||return 1
[[ $line =~ ^[0-9]+$ ]]||return 1
((line>=1))||return 1
sed -n "${line}p" "$file"
}
__trace_find_marker__(){
local file="${1:-}" line="${2:-0}" row="" n=0 src="" src_start=0
[[ -f $file ]]||return 1
[[ $line =~ ^[0-9]+$ ]]||return 1
while IFS= read -r row||[[ -n $row ]];do
n=$((n+1))
((n>line))&&break
[[ $row == __file_marker__* ]]||continue
src="${row#__file_marker__ }"
src_start="$n"
done <"$file"
[[ -n $src ]]||return 1
printf '%s\t%s\n' "$src" "$src_start"
}
__trace_find_best_line__(){
local src_file="${1:-}" final_file="${2:-}" final_line="${3:-0}" marker_line="${4:-0}"
local fallback=1 best=""
[[ -f $src_file ]]||return 1
[[ -f $final_file ]]||return 1
[[ $final_line =~ ^[0-9]+$ ]]||return 1
[[ $marker_line =~ ^[0-9]+$ ]]||return 1
fallback=$((final_line-marker_line))
((fallback>=1))||fallback=1
best="$(awk -v src_file="$src_file" -v final_file="$final_file" -v final_line="$final_line" -v fallback="$fallback" '
            function trim ( s ) {
                sub(/^[[:space:]]+/, "", s)
                sub(/[[:space:]]+$/, "", s)
                return s
            }
            BEGIN {

                for (i = -2; i <= 2; i++) {
                    idx = final_line + i
                    if (idx < 1) {
                        ctx[i] = ""
                        continue
                    }

                    cmd = "sed -n \047" idx "p\047 " "\"" final_file "\""
                    cmd | getline row
                    close(cmd)

                    if (row ~ /^__file_marker__[[:space:]]+/) row = ""
                    ctx[i] = trim(row)
                }

                for (i = 1; (getline row < src_file) > 0; i++) {
                    src[i] = trim(row)
                }
                close(src_file)

                best_score = -1
                best_line  = fallback

                for (i = 1; i <= length(src); i++) {

                    score = 0

                    if (ctx[0]  != "" && src[i]   == ctx[0])  score += 16
                    if (ctx[-1] != "" && i > 1              && src[i-1] == ctx[-1]) score += 8
                    if (ctx[1]  != "" && i < length(src)    && src[i+1] == ctx[1])  score += 8
                    if (ctx[-2] != "" && i > 2              && src[i-2] == ctx[-2]) score += 4
                    if (ctx[2]  != "" && i + 2 <= length(src) && src[i+2] == ctx[2]) score += 4

                    if (score > best_score) {
                        best_score = score
                        best_line = i
                    }
                }

                if (best_score <= 0) best_line = fallback
                if (best_line < 1)   best_line = 1

                print best_line
            }
        ')"||true
[[ $best =~ ^[0-9]+$ ]]||best="$fallback"
((best>=1))||best=1
printf '%s\n' "$best"
}
__trace_map_text__(){
local text="${1:-}" file="" line="" msg=""
local src="" marker_line=0 src_line=0
[[ -n $text ]]||return 1
file="$(sed -n 's/^\(.*\): line [0-9][0-9]*: .*/\1/p' <<<"$text"|head -n 1)"
line="$(sed -n 's/^.*: line \([0-9][0-9]*\): .*/\1/p' <<<"$text"|head -n 1)"
msg="$(sed -n 's/^.*: line [0-9][0-9]*: \(.*\)$/\1/p' <<<"$text"|head -n 1)"
[[ -f $file ]]||return 1
[[ $line =~ ^[0-9]+$ ]]||return 1
IFS=$'\t' read -r src marker_line < <(__trace_find_marker__ "$file" "$line")||return 1
[[ -f $src ]]||return 1
src_line="$(__trace_find_best_line__ "$src" "$file" "$line" "$marker_line")"||return 1
printf '%s:%s: %s\n' "$src" "$src_line" "$msg" >&3
}
__trace_map_line__(){
local file="${1:-}" line="${2:-0}" msg="${3:-}"
local src="" marker_line=0 src_line=0
[[ -f $file ]]||{
printf '%s: line %s: %s\n' "$file" "$line" "$msg" >&3
return 1
}
[[ $line =~ ^[0-9]+$ ]]||{
printf '%s: line %s: %s\n' "$file" "$line" "$msg" >&3
return 1
}
IFS=$'\t' read -r src marker_line < <(__trace_find_marker__ "$file" "$line")||{
printf '%s: line %s: %s\n' "$file" "$line" "$msg" >&3
return 1
}
[[ -f $src ]]||{
printf '%s: line %s: %s\n' "$file" "$line" "$msg" >&3
return 1
}
src_line="$(__trace_find_best_line__ "$src" "$file" "$line" "$marker_line")"||src_line=0
[[ $src_line =~ ^[0-9]+$ ]]||src_line=$((line-marker_line))
((src_line>=1))||src_line=1
printf '%s:%s: %s\n' "$src" "$src_line" "$msg" >&3
}
__trace_stderr__(){
local line="" pat=""
pat="^$___TRACE_FILE___: line [0-9][0-9]*: "
while IFS= read -r line||[[ -n $line ]];do
[[ $line == "__TRACE_EOF__" ]]&&break
if [[ $line =~ $pat ]];then
__trace_map_text__ "$line"||printf '%s\n' "$line" >&3
continue
fi
printf '%s\n' "$line" >&3
done
}
__trace_on_err__(){
local rc="${1:-1}" line="${2:-0}" cmd="${3:-}"
case "$rc" in
126|127)return 0
esac
__trace_map_line__ "$___TRACE_FILE___" "$line" "$cmd: exit $rc"||true
}
__trace_cleanup__(){
local rc="${1:-0}"
trap - ERR EXIT
printf '%s\n' '__TRACE_EOF__' >&2||true
exec 2>&3||true
exec 9>&-||true
exec 3>&-||true
[[ -n ${___TRACE_PID___:-} ]]&&wait "$___TRACE_PID___" 2>/dev/null||true
[[ -n ${___TRACE_FIFO___:-} ]]&&rm -f "$___TRACE_FIFO___" 2>/dev/null||true
exit "$rc"
}
readonly ___TRACE_FILE___="${BASH_SOURCE[0]}"
readonly ___TRACE_FIFO___="$(mktemp -u "${TMPDIR:-/tmp}/gun-trace.XXXXXX")"
mkfifo "$___TRACE_FIFO___"||exit 1
exec 3>&2
exec 8<>"$___TRACE_FIFO___"
exec 9>"$___TRACE_FIFO___"
__trace_stderr__ <&8&
readonly ___TRACE_PID___=$!
exec 2>&9
trap 'rc=$?; __trace_on_err__ "${rc}" "${LINENO}" "${BASH_COMMAND}"; __trace_cleanup__ "${rc}"' ERR
trap 'rc=$?; __trace_cleanup__ "${rc}"' EXIT
__file_marker__ /var/www/projects/gun/src/core/app/env.sh
echo "start"
(echo "pipe-sub"
missing_runtime_cmd_10)|cat
echo "end"
__file_marker__ /var/www/projects/gun/src/core/app/log.sh
__file_marker__ /var/www/projects/gun/src/core/app/read.sh
__file_marker__ /var/www/projects/gun/src/core/app/run.sh
__file_marker__ /var/www/projects/gun/src/core/context/facade.sh
__file_marker__ /var/www/projects/gun/src/core/parse/facade.sh
__file_marker__ /var/www/projects/gun/src/main.sh
function quality(){
echo "Quality Passed"
}
test_quality1(){
echo "Qsuality 1 Passed"
}
main(){
trace_prod
echos "Hello World"
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
readonly ___APP_SRC_CHECKSUM___='86ce009dee19139863b94e65dd94f777a6212bb2a5ac017fb2a1009326217059'
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

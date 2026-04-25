#!/usr/bin/env bash
# shellcheck shell=bash

set -u
set -o pipefail

TARGET="${1:-tool/parts/builtin/log.sh}"

pass=0
fail=0

ok () {

    printf '[PASS] %s\n' "$1"
    pass=$(( pass + 1 ))

}

bad () {

    printf '[FAIL] %s\n  want: [%s]\n  got : [%s]\n' "$1" "$2" "$3"
    fail=$(( fail + 1 ))

}

eq () {

    local name="$1" want="$2" got="$3"

    [[ "${got}" == "${want}" ]] && ok "${name}" || bad "${name}" "${want}" "${got}"

}

has () {

    local name="$1" needle="$2" got="$3"

    [[ "${got}" == *"${needle}"* ]] && ok "${name}" || bad "${name}" "*${needle}*" "${got}"

}

nohas () {

    local name="$1" needle="$2" got="$3"

    [[ "${got}" != *"${needle}"* ]] && ok "${name}" || bad "${name}" "not containing ${needle}" "${got}"

}

rc_ok () {

    local name="$1"
    shift

    if "$@"; then ok "${name}"
    else bad "${name}" "exit=0" "exit=$?"
    fi

}

rc_no () {

    local name="$1"
    shift

    if "$@"; then bad "${name}" "exit!=0" "exit=0"
    else ok "${name}"
    fi

}

section () {

    printf '\n== %s ==\n' "$1"

}

run_out () {

    bash -c 'source "$1"; shift; eval "$1"' _ "${TARGET}" "$1"

}

run_err () {

    bash -c 'source "$1"; shift; eval "$1"' _ "${TARGET}" "$1" 2>&1 >/dev/null

}

run_both () {

    bash -c 'source "$1"; shift; eval "$1"' _ "${TARGET}" "$1" 2>&1

}

if [[ ! -r "${TARGET}" ]]; then
    printf '[ERR] target not readable: %s\n' "${TARGET}" >&2
    exit 2
fi

section "syntax / static checks"

rc_ok "bash -n target" bash -n "${TARGET}"

if command -v shellcheck >/dev/null 2>&1; then
    rc_ok "shellcheck target" shellcheck "${TARGET}"
else
    ok "shellcheck skipped"
fi

# shellcheck source=/dev/null
source "${TARGET}"

section "public api"

required=(
    log::is_tty
    log::is_err_tty
    log::is_quiet
    log::is_verbose
    log::supports_color
    log::supports_unicode
    log::level_num
    log::enabled
    log::color
    log::strip
    log::symbol
    log::timestamp
    log::emit
    log::print
    log::line
    log::raw
    log::err
    log::info
    log::ok
    log::success
    log::done
    log::warn
    log::warning
    log::error
    log::fail
    log::debug
    log::trace
    log::step
    log::fatal
    log::die
    log::title
    log::section
    log::subsection
    log::hr
    log::kv
    log::pair
    log::list
    log::item
    log::cmd
    log::quote
    log::indent
    log::table
    log::status
    log::run
    log::try
    log::plain
    log::quiet
    log::verbose
    log::with_color
    log::without_color
)

for fn in "${required[@]}"; do
    rc_ok "function exists: ${fn}" declare -F "${fn}"
done

section "level numbers / enabled"

eq "level trace" "0" "$(log::level_num trace)"
eq "level debug" "1" "$(log::level_num debug)"
eq "level info" "2" "$(log::level_num info)"
eq "level warn" "3" "$(log::level_num warn)"
eq "level error" "4" "$(log::level_num error)"
eq "level off" "9" "$(log::level_num off)"
eq "level unknown defaults info" "2" "$(log::level_num wat)"

rc_ok "enabled info at default" env -i PATH="${PATH}" bash -c 'source "$1"; log::enabled info' _ "${TARGET}"
rc_no "debug disabled at default" env -i PATH="${PATH}" bash -c 'source "$1"; log::enabled debug' _ "${TARGET}"
rc_ok "warn enabled at info" env -i PATH="${PATH}" bash -c 'source "$1"; LOG_LEVEL=info log::enabled warn' _ "${TARGET}"
rc_no "info disabled at warn" env -i PATH="${PATH}" bash -c 'source "$1"; LOG_LEVEL=warn log::enabled info' _ "${TARGET}"
rc_ok "error enabled under quiet" env -i PATH="${PATH}" bash -c 'source "$1"; QUIET=1 log::enabled error' _ "${TARGET}"
rc_no "info disabled under quiet" env -i PATH="${PATH}" bash -c 'source "$1"; QUIET=1 log::enabled info' _ "${TARGET}"

section "color / strip / unicode"

eq "color disabled by NO_COLOR" "hello" "$(NO_COLOR=1 log::color 31 hello)"

colored="$(run_out 'unset NO_COLOR; LOG_COLOR=always; log::color 31 hello')"
has "color forced contains escape" $'\033[31m' "${colored}"
has "color forced contains reset" $'\033[0m' "${colored}"

eq "strip ansi" "hello" "$(printf '\033[31mhello\033[0m\n' | log::strip)"

eq "ascii symbol ok" "+" "$(LOG_ASCII=1 log::symbol ok)"
eq "ascii symbol error" "x" "$(LOG_ASCII=1 log::symbol error)"
eq "ascii symbol item" "-" "$(LOG_ASCII=1 log::symbol item)"

section "stdout helpers"

eq "print stdout" "abc" "$(run_out 'log::print abc')"
eq "line stdout" "abc" "$(run_out 'log::line abc')"
eq "raw stdout" "a b" "$(run_out 'printf "a b" | log::raw')"

eq "quiet suppresses print" "" "$(run_out 'QUIET=1 log::print abc')"
eq "quiet suppresses line" "" "$(run_out 'QUIET=1 log::line abc')"
eq "quiet suppresses raw" "" "$(run_out 'export QUIET=1; printf abc | log::raw')"

section "stderr basic logs"

err="$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::info "hello"')"
has "info has tag" "[INFO]" "${err}"
has "info has msg" "hello" "${err}"

err="$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::ok "good"')"
has "ok has tag" "[OK]" "${err}"
has "ok has msg" "good" "${err}"

err="$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::success "good"')"
has "success alias ok" "[OK]" "${err}"

err="$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::warn "careful"')"
has "warn has tag" "[WARN]" "${err}"

err="$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::warning "careful"')"
has "warning alias warn" "[WARN]" "${err}"

err="$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::error "bad"')"
has "error has tag" "[ERROR]" "${err}"

err="$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::fail "bad"')"
has "fail alias error" "[ERROR]" "${err}"

err="$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::done "done"')"
has "done has tag" "[DONE]" "${err}"

err="$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::step "step"')"
has "step has tag" "[STEP]" "${err}"

section "debug / trace"

eq "debug hidden by default" "" "$(run_err 'NO_COLOR=1 log::debug hidden')"
has "debug visible with DEBUG=1" "[DEBUG]" "$(run_err 'NO_COLOR=1 LOG_ASCII=1 DEBUG=1 log::debug visible')"
has "debug visible with LOG_LEVEL=debug" "[DEBUG]" "$(run_err 'NO_COLOR=1 LOG_ASCII=1 LOG_LEVEL=debug log::debug visible')"

eq "trace hidden by default" "" "$(run_err 'NO_COLOR=1 log::trace hidden')"
has "trace visible with TRACE=1" "[TRACE]" "$(run_err 'NO_COLOR=1 LOG_ASCII=1 TRACE=1 log::trace visible')"
has "trace visible with LOG_LEVEL=trace" "[TRACE]" "$(run_err 'NO_COLOR=1 LOG_ASCII=1 LOG_LEVEL=trace log::trace visible')"

section "quiet / level filtering"

eq "quiet suppresses info" "" "$(run_err 'NO_COLOR=1 QUIET=1 log::info hidden')"
has "quiet keeps error" "[ERROR]" "$(run_err 'NO_COLOR=1 LOG_ASCII=1 QUIET=1 log::error visible')"

eq "LOG_LEVEL warn suppresses info" "" "$(run_err 'NO_COLOR=1 LOG_LEVEL=warn log::info hidden')"
has "LOG_LEVEL warn keeps warn" "[WARN]" "$(run_err 'NO_COLOR=1 LOG_ASCII=1 LOG_LEVEL=warn log::warn visible')"
has "LOG_LEVEL warn keeps error" "[ERROR]" "$(run_err 'NO_COLOR=1 LOG_ASCII=1 LOG_LEVEL=warn log::error visible')"

section "timestamp"

err="$(run_err 'NO_COLOR=1 LOG_ASCII=1 LOG_TIME=1 log::info timed')"
has "timestamp includes message" "timed" "${err}"
[[ "${err}" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]] && ok "timestamp date format" || bad "timestamp date format" "YYYY-MM-DD" "${err}"

section "format helpers"

err="$(run_err 'NO_COLOR=1 log::title "Build"')"
has "title contains text" "Build" "${err}"
has "title underline" "=====" "${err}"

err="$(run_err 'NO_COLOR=1 log::section "Checks"')"
has "section format" "== Checks ==" "${err}"

err="$(run_err 'NO_COLOR=1 log::subsection "Lint"')"
has "subsection format" "-- Lint --" "${err}"

err="$(run_err 'NO_COLOR=1 log::hr "*" 5')"
eq "hr width" "*****" "${err}"

err="$(run_err 'NO_COLOR=1 log::kv Project gun 10')"
has "kv key" "Project" "${err}"
has "kv value" "gun" "${err}"

err="$(run_err 'NO_COLOR=1 log::pair Runtime bash 10')"
has "pair alias key" "Runtime" "${err}"
has "pair alias value" "bash" "${err}"

err="$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::list one "two words" "*"')"
has "list item one" "one" "${err}"
has "list item spaces" "two words" "${err}"
has "list item star" "*" "${err}"

err="$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::item "single item"')"
has "item output" "single item" "${err}"

err="$(run_err 'NO_COLOR=1 log::cmd echo hello')"
has "cmd prefix" "$ echo hello" "${err}"

err="$(run_err 'NO_COLOR=1 printf "a\nb\n" | log::quote')"
has "quote first" "| a" "${err}"
has "quote second" "| b" "${err}"

err="$(run_err 'printf "a\nb\n" | log::indent 4')"
has "indent first" "    a" "${err}"
has "indent second" "    b" "${err}"

err="$(run_err 'NO_COLOR=1 log::table 8 Name Gun Lang Bash')"
has "table name" "Name" "${err}"
has "table gun" "Gun" "${err}"
has "table lang" "Lang" "${err}"
has "table bash" "Bash" "${err}"

section "status"

has "status ok" "[OK]" "$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::status ok good')"
has "status warn" "[WARN]" "$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::status warn careful')"
has "status error" "[ERROR]" "$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::status error bad')"
has "status debug hidden default" "" "$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::status debug hidden')"
has "status unknown info" "[INFO]" "$(run_err 'NO_COLOR=1 LOG_ASCII=1 log::status custom message')"

section "fatal / die"

rc_no "fatal returns non-zero" bash -c 'source "$1"; log::fatal 7 bad >/dev/null 2>&1' _ "${TARGET}"

bash -c 'source "$1"; log::fatal 7 bad >/dev/null 2>&1' _ "${TARGET}"
code=$?
eq "fatal exact return code" "7" "${code}"

bash -c 'source "$1"; log::die 9 dead >/dev/null 2>&1' _ "${TARGET}"
code=$?
eq "die exits exact code" "9" "${code}"

section "run / try"

out="$(run_both 'NO_COLOR=1 log::run bash -c "printf ok"')"
has "run prints command" "$ bash -c printf ok" "${out}"
has "run executes command" "ok" "${out}"

bash -c 'source "$1"; log::run bash -c "exit 6" >/dev/null 2>&1' _ "${TARGET}"
code=$?
eq "run returns command code" "6" "${code}"

out="$(run_both 'NO_COLOR=1 LOG_ASCII=1 log::try bash -c "printf ok"')"
has "try success command" "$ bash -c printf ok" "${out}"
has "try success output" "ok" "${out}"
has "try success log" "Command succeeded" "${out}"

bash -c 'source "$1"; log::try bash -c "exit 5" >/dev/null 2>&1' _ "${TARGET}"
code=$?
eq "try failure returns command code" "5" "${code}"

err="$(run_both 'NO_COLOR=1 LOG_ASCII=1 log::try bash -c "exit 5"')"
has "try failure message" "Command failed with exit code 5" "${err}"

section "wrappers"

eq "without_color disables ansi" "hello" "$(run_out 'log::without_color log::color 31 hello')"
has "with_color forces ansi" $'\033[31m' "$(run_out 'log::with_color log::color 31 hello')"

eq "quiet wrapper suppresses line" "" "$(run_out 'log::quiet log::line hidden')"

section "result"

printf '\npass: %s\n' "${pass}"
printf 'fail: %s\n' "${fail}"

(( fail == 0 ))

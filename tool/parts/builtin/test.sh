#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${ROOT}/env.sh"

__T_TOTAL=0
__T_PASS=0
__T_FAIL=0

t::pass () {

    local name="${1:-}"

    __T_PASS=$((__T_PASS + 1))
    printf '[PASS] %s\n' "${name}"

}

t::fail_case () {

    local name="${1:-}" msg="${2:-failed}"

    __T_FAIL=$((__T_FAIL + 1))
    printf '[FAIL] %s\n       %s\n' "${name}" "${msg}" >&2

}

t::run () {

    local name="${1:-}"

    shift || true
    __T_TOTAL=$((__T_TOTAL + 1))

    if "$@"; then t::pass "${name}"
    else t::fail_case "${name}"
    fi

}

t::deny () {

    local name="${1:-}"

    shift || true
    __T_TOTAL=$((__T_TOTAL + 1))

    if "$@"; then t::fail_case "${name}" "expected failure"
    else t::pass "${name}"
    fi

}

t::eq () {

    local name="${1:-}" got="${2-}" want="${3-}"

    __T_TOTAL=$((__T_TOTAL + 1))

    if [[ "${got}" == "${want}" ]]; then
        t::pass "${name}"
    else
        t::fail_case "${name}" "got: <${got}> | want: <${want}>"
    fi

}

t::line () {

    local name="${1:-}" data="${2-}" want="${3-}"

    __T_TOTAL=$((__T_TOTAL + 1))

    if printf '%s\n' "${data}" | grep -Fx -- "${want}" >/dev/null 2>&1; then
        t::pass "${name}"
    else
        t::fail_case "${name}" "missing line: <${want}>"
    fi

}

t::no_line () {

    local name="${1:-}" data="${2-}" want="${3-}"

    __T_TOTAL=$((__T_TOTAL + 1))

    if printf '%s\n' "${data}" | grep -Fx -- "${want}" >/dev/null 2>&1; then
        t::fail_case "${name}" "unexpected line: <${want}>"
    else
        t::pass "${name}"
    fi

}

t::clean () {

    unset ENV_TEST_A ENV_TEST_B ENV_TEST_C ENV_TEST_D ENV_TEST_E || true
    unset ENV_TEST_EMPTY ENV_TEST_TRUE ENV_TEST_FALSE ENV_TEST_PATH || true
    unset ENV_TEST_SPECIAL ENV_TEST_MULTI ENV_TEST_X ENV_TEST_Y || true

}

t::summary () {

    printf '%s\n' '------------------------------------------------------------'
    printf '[RESULT] total=%s pass=%s fail=%s\n' "${__T_TOTAL}" "${__T_PASS}" "${__T_FAIL}"
    (( __T_FAIL == 0 ))

}

printf '%s\n' '------------------------------------------------------------'
printf '[TEST] env.sh hard test\n'
printf '[BASH] %s\n' "${BASH_VERSION:-unknown}"
printf '%s\n' '------------------------------------------------------------'

t::clean

# valid
t::run  "valid simple"        env::valid "ENV_TEST_A"
t::run  "valid underscore"    env::valid "_ENV_TEST_A"
t::run  "valid digits tail"   env::valid "ENV_TEST_A1"
t::deny "invalid empty"       env::valid ""
t::deny "invalid digit start" env::valid "1ENV_TEST"
t::deny "invalid dash"        env::valid "ENV-TEST"
t::deny "invalid dot"         env::valid "ENV.TEST"
t::deny "invalid space"       env::valid "ENV TEST"
t::deny "invalid injection"   env::valid '$(echo hacked)'

# has / missing / empty / filled
unset ENV_TEST_A || true

t::deny "has unset"       env::has ENV_TEST_A
t::run  "missing unset"   env::missing ENV_TEST_A

export ENV_TEST_A=""
t::run  "has empty"       env::has ENV_TEST_A
t::run  "empty empty"     env::empty ENV_TEST_A
t::deny "filled empty"    env::filled ENV_TEST_A
t::deny "missing empty"   env::missing ENV_TEST_A

export ENV_TEST_A="alpha"
t::run  "has filled"      env::has ENV_TEST_A
t::run  "filled filled"   env::filled ENV_TEST_A
t::deny "empty filled"    env::empty ENV_TEST_A
t::deny "missing filled"  env::missing ENV_TEST_A

# get / set / unset / set_once / equal
env::unset ENV_TEST_A 2>/dev/null || true

t::eq  "get default unset" "$(env::get ENV_TEST_A fallback)" "fallback"
t::run "set normal" env::set ENV_TEST_A "hello"
t::eq  "get normal" "$(env::get ENV_TEST_A)" "hello"
t::run "equal true" env::equal ENV_TEST_A "hello"
t::deny "equal false" env::equal ENV_TEST_A "world"

t::run "set empty" env::set ENV_TEST_EMPTY ""
t::eq  "get empty" "$(env::get ENV_TEST_EMPTY fallback)" ""

t::run "set special" env::set ENV_TEST_SPECIAL 'a b=c:$PATH:"x";*?[z]'
t::eq  "get special" "$(env::get ENV_TEST_SPECIAL)" 'a b=c:$PATH:"x";*?[z]'

t::run "set multiline" env::set ENV_TEST_MULTI $'line1\nline2'
t::eq  "get multiline" "$(env::get ENV_TEST_MULTI)" $'line1\nline2'

t::run "set_once keeps existing call" env::set_once ENV_TEST_A "changed"
t::eq  "set_once keeps existing value" "$(env::get ENV_TEST_A)" "hello"

env::unset ENV_TEST_B 2>/dev/null || true
t::run "set_once writes missing" env::set_once ENV_TEST_B "second"
t::eq  "set_once missing value" "$(env::get ENV_TEST_B)" "second"

t::run  "unset existing" env::unset ENV_TEST_B
t::deny "unset invalid"  env::unset "BAD-NAME"

# bool
for v in 1 true TRUE True yes YES y Y on ON; do
    env::set ENV_TEST_TRUE "${v}"
    t::run "true ${v}" env::true ENV_TEST_TRUE
done

for v in 0 false FALSE False no NO n N off OFF; do
    env::set ENV_TEST_FALSE "${v}"
    t::run "false ${v}" env::false ENV_TEST_FALSE
done

env::set ENV_TEST_TRUE "maybe"
t::deny "true rejects maybe"  env::true ENV_TEST_TRUE
t::deny "false rejects maybe" env::false ENV_TEST_TRUE

env::set ENV_TEST_TRUE ""
t::deny "true rejects empty"  env::true ENV_TEST_TRUE
t::deny "false rejects empty" env::false ENV_TEST_TRUE

# any/all
unset ENV_TEST_A ENV_TEST_B ENV_TEST_C || true
env::set ENV_TEST_A "a"
env::set ENV_TEST_B "b"

t::run  "has_any one"      env::has_any ENV_TEST_X ENV_TEST_A ENV_TEST_Y
t::deny "has_any none"     env::has_any ENV_TEST_X ENV_TEST_Y
t::run  "has_all all"      env::has_all ENV_TEST_A ENV_TEST_B
t::deny "has_all missing"  env::has_all ENV_TEST_A ENV_TEST_C

t::run "need success"     env::need ENV_TEST_A ENV_TEST_B
t::run "need_all success" env::need_all ENV_TEST_A ENV_TEST_B
t::run "need_any success" env::need_any ENV_TEST_X ENV_TEST_A ENV_TEST_Y

# bulk
env::unset_all ENV_TEST_A ENV_TEST_B ENV_TEST_C ENV_TEST_EMPTY 2>/dev/null || true

t::run "set_all" env::set_all ENV_TEST_A=one ENV_TEST_B=two ENV_TEST_EMPTY=
bulk_out="$(env::get_all ENV_TEST_A ENV_TEST_B ENV_TEST_EMPTY)"

t::line "get_all A" "${bulk_out}" "ENV_TEST_A=one"
t::line "get_all B" "${bulk_out}" "ENV_TEST_B=two"
t::line "get_all empty" "${bulk_out}" "ENV_TEST_EMPTY="

t::deny "set_all invalid pair" env::set_all ENV_TEST_A
t::deny "set_all invalid key"  env::set_all BAD-NAME=value

t::run "set_all_once" env::set_all_once ENV_TEST_A=changed ENV_TEST_C=three
t::eq  "set_all_once keeps" "$(env::get ENV_TEST_A)" "one"
t::eq  "set_all_once sets" "$(env::get ENV_TEST_C)" "three"

t::run  "unset_all" env::unset_all ENV_TEST_A ENV_TEST_B ENV_TEST_C
t::deny "unset_all gone A" env::has ENV_TEST_A
t::deny "unset_all gone B" env::has ENV_TEST_B
t::deny "unset_all gone C" env::has ENV_TEST_C

# list / keys / values
t::clean
env::set ENV_TEST_A "aaa"
env::set ENV_TEST_B "bbb"
env::set ENV_TEST_EMPTY ""

keys_out="$(env::keys ENV_TEST_)"
values_out="$(env::values ENV_TEST_)"
list_out="$(env::list ENV_TEST_)"

t::line "keys A" "${keys_out}" "ENV_TEST_A"
t::line "keys B" "${keys_out}" "ENV_TEST_B"
t::line "keys EMPTY" "${keys_out}" "ENV_TEST_EMPTY"

t::line "values aaa" "${values_out}" "aaa"
t::line "values bbb" "${values_out}" "bbb"

t::line "list A" "${list_out}" "ENV_TEST_A=aaa"
t::line "list B" "${list_out}" "ENV_TEST_B=bbb"
t::line "list EMPTY" "${list_out}" "ENV_TEST_EMPTY="
t::no_line "prefix excludes PATH" "${keys_out}" "PATH"

# refs
if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 3) )); then

    declare -a env_keys_ref=()
    declare -a env_values_ref=()
    declare -a env_list_ref=()

    t::run "keys_ref"   env::keys_ref env_keys_ref ENV_TEST_
    t::run "values_ref" env::values_ref env_values_ref ENV_TEST_
    t::run "list_ref"   env::list_ref env_list_ref ENV_TEST_

    t::line "keys_ref A" "$(printf '%s\n' "${env_keys_ref[@]}")" "ENV_TEST_A"
    t::line "values_ref aaa" "$(printf '%s\n' "${env_values_ref[@]}")" "aaa"
    t::line "list_ref A" "$(printf '%s\n' "${env_list_ref[@]}")" "ENV_TEST_A=aaa"

else
    printf '[SKIP] *_ref tests\n'
fi

if (( BASH_VERSINFO[0] >= 4 )); then

    declare -A env_map_ref=()

    t::run "map" env::map env_map_ref ENV_TEST_
    t::eq  "map A" "${env_map_ref[ENV_TEST_A]-}" "aaa"
    t::eq  "map B" "${env_map_ref[ENV_TEST_B]-}" "bbb"
    t::eq  "map EMPTY" "${env_map_ref[ENV_TEST_EMPTY]-x}" ""

else
    printf '[SKIP] map tests\n'
fi

# path ops
env::set ENV_TEST_PATH "/bin:/usr/bin"

t::run  "path_has /bin"     env::path_has "/bin" "$(env::get ENV_TEST_PATH)"
t::run  "path_has /usr/bin" env::path_has "/usr/bin" "$(env::get ENV_TEST_PATH)"
t::deny "path_has missing"  env::path_has "/opt/nope" "$(env::get ENV_TEST_PATH)"

t::run "path_prepend new" env::path_prepend "/opt/a" ENV_TEST_PATH
t::eq  "path_prepend result" "$(env::get ENV_TEST_PATH)" "/opt/a:/bin:/usr/bin"

t::run "path_prepend duplicate" env::path_prepend "/opt/a" ENV_TEST_PATH
t::eq  "path_prepend duplicate result" "$(env::get ENV_TEST_PATH)" "/opt/a:/bin:/usr/bin"

t::run "path_append new" env::path_append "/opt/b" ENV_TEST_PATH
t::eq  "path_append result" "$(env::get ENV_TEST_PATH)" "/opt/a:/bin:/usr/bin:/opt/b"

t::run "path_append duplicate" env::path_append "/opt/b" ENV_TEST_PATH
t::eq  "path_append duplicate result" "$(env::get ENV_TEST_PATH)" "/opt/a:/bin:/usr/bin:/opt/b"

t::run "path_del middle" env::path_del "/bin" ENV_TEST_PATH
t::eq  "path_del middle result" "$(env::get ENV_TEST_PATH)" "/opt/a:/usr/bin:/opt/b"

t::run "path_del first" env::path_del "/opt/a" ENV_TEST_PATH
t::eq  "path_del first result" "$(env::get ENV_TEST_PATH)" "/usr/bin:/opt/b"

t::run "path_del last" env::path_del "/opt/b" ENV_TEST_PATH
t::eq  "path_del last result" "$(env::get ENV_TEST_PATH)" "/usr/bin"

t::run "path_del missing noop" env::path_del "/missing" ENV_TEST_PATH
t::eq  "path_del missing result" "$(env::get ENV_TEST_PATH)" "/usr/bin"

env::set ENV_TEST_PATH "/bin:/binx:/x/bin:/usr/bin"
t::run "path_del exact only" env::path_del "/bin" ENV_TEST_PATH
t::eq  "path_del exact result" "$(env::get ENV_TEST_PATH)" "/binx:/x/bin:/usr/bin"

t::deny "path invalid key"       env::path_prepend "/x" "BAD-NAME"
t::deny "path empty dir prepend" env::path_prepend "" ENV_TEST_PATH
t::deny "path empty dir append"  env::path_append "" ENV_TEST_PATH
t::deny "path empty dir del"     env::path_del "" ENV_TEST_PATH

# invalid stress
t::deny "has invalid"          env::has "BAD-NAME"
t::deny "filled invalid"       env::filled "BAD-NAME"
t::deny "empty invalid"        env::empty "BAD-NAME"
t::deny "equal invalid"        env::equal "BAD-NAME" "x"
t::deny "true invalid"         env::true "BAD-NAME"
t::deny "false invalid"        env::false "BAD-NAME"
t::deny "set invalid"          env::set "BAD-NAME" "x"
t::deny "set_once invalid"     env::set_once "BAD-NAME" "x"
t::deny "get_all invalid"      env::get_all ENV_TEST_A "BAD-NAME"
t::deny "unset_all invalid"    env::unset_all ENV_TEST_A "BAD-NAME"
t::deny "set_all_once invalid" env::set_all_once BAD-NAME=x

t::clean
unset ENV_TEST_PATH || true

t::summary

#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${ROOT}/env.sh"

__T_TOTAL=0
__T_PASS=0
__T_FAIL=0

t::ok () {

    local name="${1:-}"

    __T_TOTAL=$((__T_TOTAL + 1))

    if "$@"; then
        __T_PASS=$((__T_PASS + 1))
        printf '[PASS] %s\n' "${name}"
    else
        __T_FAIL=$((__T_FAIL + 1))
        printf '[FAIL] %s\n' "${name}" >&2
    fi

}

t::eq () {

    local name="${1:-}" got="${2-}" want="${3-}"

    __T_TOTAL=$((__T_TOTAL + 1))

    if [[ "${got}" == "${want}" ]]; then
        __T_PASS=$((__T_PASS + 1))
        printf '[PASS] %s\n' "${name}"
    else
        __T_FAIL=$((__T_FAIL + 1))
        printf '[FAIL] %s\n       got : <%s>\n       want: <%s>\n' "${name}" "${got}" "${want}" >&2
    fi

}

t::fail () {

    local name="${1:-}"
    shift || true

    __T_TOTAL=$((__T_TOTAL + 1))

    if "$@"; then
        __T_FAIL=$((__T_FAIL + 1))
        printf '[FAIL] %s\n       expected failure\n' "${name}" >&2
    else
        __T_PASS=$((__T_PASS + 1))
        printf '[PASS] %s\n' "${name}"
    fi

}

t::contains_line () {

    local name="${1:-}" data="${2-}" line="${3-}"

    __T_TOTAL=$((__T_TOTAL + 1))

    if printf '%s\n' "${data}" | grep -Fx -- "${line}" >/dev/null 2>&1; then
        __T_PASS=$((__T_PASS + 1))
        printf '[PASS] %s\n' "${name}"
    else
        __T_FAIL=$((__T_FAIL + 1))
        printf '[FAIL] %s\n       missing line: <%s>\n       data:\n%s\n' "${name}" "${line}" "${data}" >&2
    fi

}

t::not_contains_line () {

    local name="${1:-}" data="${2-}" line="${3-}"

    __T_TOTAL=$((__T_TOTAL + 1))

    if printf '%s\n' "${data}" | grep -Fx -- "${line}" >/dev/null 2>&1; then
        __T_FAIL=$((__T_FAIL + 1))
        printf '[FAIL] %s\n       unexpected line: <%s>\n       data:\n%s\n' "${name}" "${line}" "${data}" >&2
    else
        __T_PASS=$((__T_PASS + 1))
        printf '[PASS] %s\n' "${name}"
    fi

}

t::summary () {

    printf '%s\n' '------------------------------------------------------------'
    printf '[RESULT] total=%s pass=%s fail=%s\n' "${__T_TOTAL}" "${__T_PASS}" "${__T_FAIL}"

    (( __T_FAIL == 0 ))

}

t::clean () {

    unset ENV_TEST_A ENV_TEST_B ENV_TEST_C ENV_TEST_EMPTY ENV_TEST_TRUE ENV_TEST_FALSE ENV_TEST_PATH ENV_TEST_SPECIAL ENV_TEST_MULTI ENV_TEST_EQ || true

}

printf '%s\n' '------------------------------------------------------------'
printf '[TEST] env.sh hard test\n'
printf '[BASH] %s\n' "${BASH_VERSION:-unknown}"
printf '%s\n' '------------------------------------------------------------'

t::clean

# ------------------------------------------------------------
# valid
# ------------------------------------------------------------

t::ok   "valid simple"      env::valid "ENV_TEST_A"
t::ok   "valid underscore"  env::valid "_ENV_TEST_A"
t::ok   "valid digits tail" env::valid "ENV_TEST_A1"

t::fail "invalid empty"     env::valid ""
t::fail "invalid digit"     env::valid "1ENV"
t::fail "invalid dash"      env::valid "ENV-TEST"
t::fail "invalid dot"       env::valid "ENV.TEST"
t::fail "invalid space"     env::valid "ENV TEST"
t::fail "invalid command"   env::valid '$(echo hacked)'

# ------------------------------------------------------------
# has / missing / empty / filled
# ------------------------------------------------------------

unset ENV_TEST_A || true

t::fail "has unset" env::has ENV_TEST_A
t::ok   "missing unset" env::missing ENV_TEST_A

export ENV_TEST_A=""
t::ok   "has empty" env::has ENV_TEST_A
t::ok   "empty empty" env::empty ENV_TEST_A
t::fail "filled empty" env::filled ENV_TEST_A

export ENV_TEST_A="alpha"
t::ok   "has filled" env::has ENV_TEST_A
t::fail "missing filled" env::missing ENV_TEST_A
t::fail "empty filled" env::empty ENV_TEST_A
t::ok   "filled filled" env::filled ENV_TEST_A

# ------------------------------------------------------------
# get / set / unset / set_once / equal
# ------------------------------------------------------------

env::unset ENV_TEST_A || true

t::eq "get default unset" "$(env::get ENV_TEST_A fallback)" "fallback"

t::ok "set normal" env::set ENV_TEST_A "hello"
t::eq "get normal" "$(env::get ENV_TEST_A)" "hello"
t::ok "equal true" env::equal ENV_TEST_A "hello"
t::fail "equal false" env::equal ENV_TEST_A "world"

t::ok "set empty" env::set ENV_TEST_EMPTY ""
t::eq "get empty" "$(env::get ENV_TEST_EMPTY fallback)" ""

t::ok "set special chars" env::set ENV_TEST_SPECIAL 'a b=c:$PATH:"x";*?[z]'
t::eq "get special chars" "$(env::get ENV_TEST_SPECIAL)" 'a b=c:$PATH:"x";*?[z]'

t::ok "set multiline" env::set ENV_TEST_MULTI $'line1\nline2'
t::eq "get multiline" "$(env::get ENV_TEST_MULTI)" $'line1\nline2'

t::ok "set_once first" env::set_once ENV_TEST_A "first"
t::eq "set_once keeps old" "$(env::get ENV_TEST_A)" "hello"

env::unset ENV_TEST_B || true
t::ok "set_once unset" env::set_once ENV_TEST_B "second"
t::eq "set_once writes unset" "$(env::get ENV_TEST_B)" "second"

t::ok "unset existing" env::unset ENV_TEST_B
t::fail "unset invalid" env::unset "BAD-NAME"

# ------------------------------------------------------------
# true / false
# ------------------------------------------------------------

for v in 1 true TRUE True yes YES y Y on ON; do
    env::set ENV_TEST_TRUE "${v}"
    t::ok "true value ${v}" env::true ENV_TEST_TRUE
done

for v in 0 false FALSE False no NO n N off OFF; do
    env::set ENV_TEST_FALSE "${v}"
    t::ok "false value ${v}" env::false ENV_TEST_FALSE
done

env::set ENV_TEST_TRUE "maybe"
t::fail "true rejects maybe" env::true ENV_TEST_TRUE
t::fail "false rejects maybe" env::false ENV_TEST_TRUE

env::set ENV_TEST_TRUE ""
t::fail "true rejects empty" env::true ENV_TEST_TRUE
t::fail "false rejects empty" env::false ENV_TEST_TRUE

# ------------------------------------------------------------
# has_any / has_all
# ------------------------------------------------------------

unset ENV_TEST_A ENV_TEST_B ENV_TEST_C || true
env::set ENV_TEST_A "a"
env::set ENV_TEST_B "b"

t::ok   "has_any one exists" env::has_any ENV_TEST_X ENV_TEST_A ENV_TEST_Y
t::fail "has_any none"       env::has_any ENV_TEST_X ENV_TEST_Y
t::ok   "has_all all"        env::has_all ENV_TEST_A ENV_TEST_B
t::fail "has_all missing"    env::has_all ENV_TEST_A ENV_TEST_C

# ------------------------------------------------------------
# need / need_any / need_all
# note: avoid failing test process by calling only successful cases
# ------------------------------------------------------------

t::ok "need success"     env::need ENV_TEST_A ENV_TEST_B
t::ok "need_all success" env::need_all ENV_TEST_A ENV_TEST_B
t::ok "need_any success" env::need_any ENV_TEST_X ENV_TEST_A ENV_TEST_Y

# ------------------------------------------------------------
# get_all / set_all / unset_all / set_all_once
# ------------------------------------------------------------

env::unset_all ENV_TEST_A ENV_TEST_B 2>/dev/null || true

t::ok "set_all" env::set_all ENV_TEST_A=one ENV_TEST_B=two ENV_TEST_EMPTY=
t::contains_line "get_all A" "$(env::get_all ENV_TEST_A ENV_TEST_B ENV_TEST_EMPTY)" "ENV_TEST_A=one"
t::contains_line "get_all B" "$(env::get_all ENV_TEST_A ENV_TEST_B ENV_TEST_EMPTY)" "ENV_TEST_B=two"
t::contains_line "get_all empty" "$(env::get_all ENV_TEST_A ENV_TEST_B ENV_TEST_EMPTY)" "ENV_TEST_EMPTY="

t::fail "set_all invalid pair" env::set_all ENV_TEST_A
t::fail "set_all invalid key" env::set_all BAD-NAME=value

t::ok "set_all_once" env::set_all_once ENV_TEST_A=changed ENV_TEST_C=three
t::eq "set_all_once keeps existing" "$(env::get ENV_TEST_A)" "one"
t::eq "set_all_once sets missing" "$(env::get ENV_TEST_C)" "three"

t::ok "unset_all" env::unset_all ENV_TEST_A ENV_TEST_B ENV_TEST_C
t::fail "unset_all gone A" env::has ENV_TEST_A
t::fail "unset_all gone B" env::has ENV_TEST_B
t::fail "unset_all gone C" env::has ENV_TEST_C

# ------------------------------------------------------------
# keys / values / list
# ------------------------------------------------------------

t::clean
env::set ENV_TEST_A "aaa"
env::set ENV_TEST_B "bbb"
env::set ENV_TEST_EMPTY ""

keys_out="$(env::keys ENV_TEST_)"
values_out="$(env::values ENV_TEST_)"
list_out="$(env::list ENV_TEST_)"

t::contains_line "keys contains A" "${keys_out}" "ENV_TEST_A"
t::contains_line "keys contains B" "${keys_out}" "ENV_TEST_B"
t::contains_line "keys contains EMPTY" "${keys_out}" "ENV_TEST_EMPTY"

t::contains_line "values contains aaa" "${values_out}" "aaa"
t::contains_line "values contains bbb" "${values_out}" "bbb"

t::contains_line "list contains A" "${list_out}" "ENV_TEST_A=aaa"
t::contains_line "list contains B" "${list_out}" "ENV_TEST_B=bbb"
t::contains_line "list contains EMPTY" "${list_out}" "ENV_TEST_EMPTY="

t::not_contains_line "prefix excludes PATH" "${keys_out}" "PATH"

# ------------------------------------------------------------
# refs / map if supported
# ------------------------------------------------------------

if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 3) )); then

    declare -a env_keys_ref=()
    declare -a env_values_ref=()
    declare -a env_list_ref=()

    t::ok "keys_ref" env::keys_ref env_keys_ref ENV_TEST_
    t::ok "values_ref" env::values_ref env_values_ref ENV_TEST_
    t::ok "list_ref" env::list_ref env_list_ref ENV_TEST_

    t::contains_line "keys_ref contains A" "$(printf '%s\n' "${env_keys_ref[@]}")" "ENV_TEST_A"
    t::contains_line "values_ref contains aaa" "$(printf '%s\n' "${env_values_ref[@]}")" "aaa"
    t::contains_line "list_ref contains A" "$(printf '%s\n' "${env_list_ref[@]}")" "ENV_TEST_A=aaa"

else

    printf '[SKIP] *_ref tests: nameref unsupported in Bash %s\n' "${BASH_VERSION:-unknown}"

fi

if (( BASH_VERSINFO[0] >= 4 )); then

    declare -A env_map_ref=()

    t::ok "map" env::map env_map_ref ENV_TEST_
    t::eq "map A" "${env_map_ref[ENV_TEST_A]-}" "aaa"
    t::eq "map B" "${env_map_ref[ENV_TEST_B]-}" "bbb"
    t::eq "map EMPTY" "${env_map_ref[ENV_TEST_EMPTY]-x}" ""

else

    printf '[SKIP] map tests: associative arrays unsupported in Bash %s\n' "${BASH_VERSION:-unknown}"

fi

# ------------------------------------------------------------
# PATH ops
# ------------------------------------------------------------

env::set ENV_TEST_PATH "/bin:/usr/bin"

t::ok "path_has /bin" env::path_has "/bin" "$(env::get ENV_TEST_PATH)"
t::ok "path_has /usr/bin" env::path_has "/usr/bin" "$(env::get ENV_TEST_PATH)"
t::fail "path_has missing" env::path_has "/opt/nope" "$(env::get ENV_TEST_PATH)"

t::ok "path_prepend new" env::path_prepend "/opt/a" ENV_TEST_PATH
t::eq "path_prepend new result" "$(env::get ENV_TEST_PATH)" "/opt/a:/bin:/usr/bin"

t::ok "path_prepend duplicate" env::path_prepend "/opt/a" ENV_TEST_PATH
t::eq "path_prepend duplicate result" "$(env::get ENV_TEST_PATH)" "/opt/a:/bin:/usr/bin"

t::ok "path_append new" env::path_append "/opt/b" ENV_TEST_PATH
t::eq "path_append new result" "$(env::get ENV_TEST_PATH)" "/opt/a:/bin:/usr/bin:/opt/b"

t::ok "path_append duplicate" env::path_append "/opt/b" ENV_TEST_PATH
t::eq "path_append duplicate result" "$(env::get ENV_TEST_PATH)" "/opt/a:/bin:/usr/bin:/opt/b"

t::ok "path_del middle" env::path_del "/bin" ENV_TEST_PATH
t::eq "path_del middle result" "$(env::get ENV_TEST_PATH)" "/opt/a:/usr/bin:/opt/b"

t::ok "path_del first" env::path_del "/opt/a" ENV_TEST_PATH
t::eq "path_del first result" "$(env::get ENV_TEST_PATH)" "/usr/bin:/opt/b"

t::ok "path_del last" env::path_del "/opt/b" ENV_TEST_PATH
t::eq "path_del last result" "$(env::get ENV_TEST_PATH)" "/usr/bin"

t::ok "path_del missing noop" env::path_del "/missing" ENV_TEST_PATH
t::eq "path_del missing result" "$(env::get ENV_TEST_PATH)" "/usr/bin"

# tricky similar paths
env::set ENV_TEST_PATH "/bin:/binx:/x/bin:/usr/bin"

t::ok "path_del exact only" env::path_del "/bin" ENV_TEST_PATH
t::eq "path_del exact only result" "$(env::get ENV_TEST_PATH)" "/binx:/x/bin:/usr/bin"

t::fail "path invalid key" env::path_prepend "/x" "BAD-NAME"
t::fail "path empty dir prepend" env::path_prepend "" ENV_TEST_PATH
t::fail "path empty dir append" env::path_append "" ENV_TEST_PATH
t::fail "path empty dir del" env::path_del "" ENV_TEST_PATH

# ------------------------------------------------------------
# invalid inputs stress
# ------------------------------------------------------------

t::fail "has invalid" env::has "BAD-NAME"
t::fail "filled invalid" env::filled "BAD-NAME"
t::fail "empty invalid" env::empty "BAD-NAME"
t::fail "equal invalid" env::equal "BAD-NAME" "x"
t::fail "true invalid" env::true "BAD-NAME"
t::fail "false invalid" env::false "BAD-NAME"
t::fail "set invalid" env::set "BAD-NAME" "x"
t::fail "set_once invalid" env::set_once "BAD-NAME" "x"
t::fail "get_all invalid" env::get_all ENV_TEST_A "BAD-NAME"
t::fail "unset_all invalid" env::unset_all ENV_TEST_A "BAD-NAME"
t::fail "set_all_once invalid" env::set_all_once BAD-NAME=x

# ------------------------------------------------------------
# cleanup + summary
# ------------------------------------------------------------

t::clean
unset ENV_TEST_PATH || true

t::summary

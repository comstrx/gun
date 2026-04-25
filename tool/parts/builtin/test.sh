#!/usr/bin/env bash
# shellcheck shell=bash

set -u
set -o pipefail

CAST="${1:-tool/parts/builtin/cast.sh}"
DAILY="${2:-tool/parts/builtin/daily.sh}"

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

section () {

    printf '\n== %s ==\n' "$1"

}

eq () {

    local name="$1" want="$2" got="$3"

    [[ "${got}" == "${want}" ]] && ok "${name}" || bad "${name}" "${want}" "${got}"

}

ne () {

    local name="$1" not="$2" got="$3"

    [[ "${got}" != "${not}" ]] && ok "${name}" || bad "${name}" "not ${not}" "${got}"

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

run () {

    bash -c 'source "$1"; source "$2"; shift 2; "$@"' _ "${CAST}" "${DAILY}" "$@"

}

run_eval () {

    bash -c 'source "$1"; source "$2"; shift 2; eval "$*"' _ "${CAST}" "${DAILY}" "$@"

}
rc_ok_silent () {

    local name="$1" tmp="" code=0
    shift

    tmp="$(mktemp 2>/dev/null || printf '/tmp/test-stderr-%s-%s' "$$" "${RANDOM:-0}")"

    "$@" >/dev/null 2>"${tmp}"
    code=$?

    if (( code != 0 )); then
        bad "${name}" "exit=0" "exit=${code}"
        rm -f "${tmp}" 2>/dev/null || true
        return 1
    fi

    if [[ -s "${tmp}" ]]; then
        bad "${name}" "stderr empty" "$(cat "${tmp}")"
        rm -f "${tmp}" 2>/dev/null || true
        return 1
    fi

    rm -f "${tmp}" 2>/dev/null || true
    ok "${name}"

}

if [[ ! -r "${CAST}" ]]; then
    printf '[ERR] cast not readable: %s\n' "${CAST}" >&2
    exit 2
fi

if [[ ! -r "${DAILY}" ]]; then
    printf '[ERR] daily not readable: %s\n' "${DAILY}" >&2
    exit 2
fi

section "syntax / static checks"

rc_ok "bash -n cast.sh" bash -n "${CAST}"
rc_ok "bash -n daily.sh" bash -n "${DAILY}"

if command -v shellcheck >/dev/null 2>&1; then
    rc_ok "shellcheck cast.sh" shellcheck "${CAST}"
    rc_ok "shellcheck daily.sh" shellcheck "${DAILY}"
else
    ok "shellcheck skipped"
fi

# shellcheck source=/dev/null
source "${CAST}"

# shellcheck source=/dev/null
source "${DAILY}"

section "public api"

functions=(
    int uint float number abs char str bool
    is_int is_uint is_float is_number is_char is_str is_bool is_true is_false is_list is_map
    typeof defined filled missed empty
    use not default coalesce
    assert_eq assert_ne
)

for fn in "${functions[@]}"; do
    rc_ok "function exists: ${fn}" declare -F "${fn}"
done

section "int"

eq "int empty" "0" "$(int "")"
eq "int missing arg" "0" "$(int)"
eq "int true" "1" "$(int true)"
eq "int yes" "1" "$(int yes)"
eq "int y" "1" "$(int y)"
eq "int on" "1" "$(int on)"
eq "int false" "0" "$(int false)"
eq "int no" "0" "$(int no)"
eq "int n" "0" "$(int n)"
eq "int off" "0" "$(int off)"
eq "int positive" "123" "$(int "123")"
eq "int negative" "-123" "$(int "-123")"
eq "int plus" "+123" "$(int "+123")"
eq "int spaces" "-42" "$(int "   -42  ")"
eq "int prefix number" "99" "$(int "99abc")"
eq "int from float" "12" "$(int "12.9")"
eq "int from negative float" "-12" "$(int "-12.9")"
eq "int from leading dot" "0" "$(int ".9")"
eq "int invalid" "0" "$(int "abc")"

section "uint"

eq "uint empty" "0" "$(uint "")"
eq "uint positive" "42" "$(uint "42")"
eq "uint plus stripped" "42" "$(uint "+42")"
eq "uint negative clamps zero" "0" "$(uint "-42")"
eq "uint true" "1" "$(uint true)"
eq "uint false" "0" "$(uint false)"
eq "uint float" "12" "$(uint "12.9")"
eq "uint invalid" "0" "$(uint "wat")"

section "float / number"

eq "float empty" "0.0" "$(float "")"
eq "float true" "1.0" "$(float true)"
eq "float false" "0.0" "$(float false)"
eq "float int" "12.0" "$(float "12")"
eq "float plus int" "+12.0" "$(float "+12")"
eq "float negative int" "-12.0" "$(float "-12")"
eq "float decimal" "12.50" "$(float "12.50")"
eq "float trailing dot" "12." "$(float "12.")"
eq "float leading dot" "0.5" "$(float ".5")"
eq "float plus leading dot" "+0.5" "$(float "+.5")"
eq "float negative leading dot" "-0.5" "$(float "-.5")"
eq "float prefix" "7.2" "$(float "7.2abc")"
eq "float invalid" "0.0" "$(float "abc")"
eq "number alias" "7.0" "$(number "7")"

section "abs / char / str / bool"

eq "abs positive" "9" "$(abs "9")"
eq "abs negative" "9" "$(abs "-9")"
eq "abs plus" "9" "$(abs "+9")"
eq "abs bool true" "1" "$(abs true)"
eq "abs invalid" "0" "$(abs "abc")"

eq "char empty" "" "$(char "")"
eq "char ascii" "a" "$(char "abc")"
eq "char digit" "1" "$(char "123")"
eq "char star" "*" "$(char "*xx")"

eq "str empty" "" "$(str "")"
eq "str preserves spaces" "  hello  " "$(str "  hello  ")"
eq "str special" "a*b?c" "$(str "a*b?c")"

eq "bool true" "1" "$(bool true)"
eq "bool yes" "1" "$(bool yes)"
eq "bool y" "1" "$(bool y)"
eq "bool on" "1" "$(bool on)"
eq "bool 1" "1" "$(bool 1)"
eq "bool false" "0" "$(bool false)"
eq "bool no" "0" "$(bool no)"
eq "bool 0" "0" "$(bool 0)"
eq "bool invalid" "0" "$(bool wat)"
eq "bool empty" "0" "$(bool "")"

section "is_int / is_uint / is_float / is_number"

for v in 0 1 -1 +1 123 "  -7  " true false yes no on off y n; do
    rc_ok "is_int accepts: ${v}" is_int "${v}"
done

for v in "" "1.2" ".2" "abc" "--1" "1x"; do
    rc_no "is_int rejects: ${v}" is_int "${v}"
done

for v in 0 1 +1 123 "  +7  " true false yes no; do
    rc_ok "is_uint accepts: ${v}" is_uint "${v}"
done

for v in -1 "1.2" ".2" "abc" ""; do
    rc_no "is_uint rejects: ${v}" is_uint "${v}"
done

for v in 0 1 -1 +1 1.2 -1.2 +1.2 .5 -.5 +.5 5. "  7.0  " true false yes no; do
    rc_ok "is_float accepts: ${v}" is_float "${v}"
    rc_ok "is_number accepts: ${v}" is_number "${v}"
done

for v in "" "." "+" "-" "+." "-." "abc" "1.2.3"; do
    rc_no "is_float rejects: ${v}" is_float "${v}"
    rc_no "is_number rejects: ${v}" is_number "${v}"
done

section "is_bool / is_true / is_false"

for v in 1 0 true false yes no y n on off; do
    rc_ok "is_bool accepts: ${v}" is_bool "${v}"
done

for v in "" maybe 2 enabled disabled; do
    rc_no "is_bool rejects: ${v}" is_bool "${v}"
done

for v in 1 true yes y on; do
    rc_ok "is_true accepts: ${v}" is_true "${v}"
    rc_no "is_false rejects true value: ${v}" is_false "${v}"
done

for v in 0 false no n off "" maybe; do
    rc_no "is_true rejects: ${v}" is_true "${v}"
    rc_ok "is_false accepts non-true: ${v}" is_false "${v}"
done

section "is_char / is_str / is_list / is_map"

rc_no "is_char empty rejects" is_char ""
rc_ok "is_char one ascii" is_char "a"
rc_no "is_char two ascii rejects" is_char "ab"
rc_ok "is_char star" is_char "*"

scalar="hello"
empty_scalar=""
arr=(a b "c d")
declare -A map=([a]=1 [b]=2)

rc_ok "is_str literal" is_str "hello"
rc_ok "is_str scalar var name" is_str scalar
rc_ok "is_str empty scalar var name" is_str empty_scalar
rc_no "is_str list var rejects" is_str arr
rc_no "is_str map var rejects" is_str map

rc_ok "is_list arr" is_list arr
rc_no "is_list map rejects" is_list map
rc_no "is_list scalar rejects" is_list scalar
rc_no "is_list missing rejects" is_list no_such_array

rc_ok "is_map map" is_map map
rc_no "is_map arr rejects" is_map arr
rc_no "is_map scalar rejects" is_map scalar
rc_no "is_map missing rejects" is_map no_such_map

section "typeof values"

eq "typeof empty literal" "empty" "$(typeof "")"
eq "typeof bool true" "bool" "$(typeof true)"
eq "typeof bool false" "bool" "$(typeof false)"
eq "typeof int" "int" "$(typeof "123")"
eq "typeof negative int" "int" "$(typeof "-123")"
eq "typeof float" "float" "$(typeof "12.5")"
eq "typeof leading dot float" "float" "$(typeof ".5")"
eq "typeof char" "char" "$(typeof "x")"
eq "typeof str" "str" "$(typeof "hello")"
eq "typeof invalid str" "str" "$(typeof "abc123x")"

section "typeof variables"

x_int=123
x_float=1.5
x_bool=true
x_char=z
x_str=hello
x_empty=""
x_arr=(a b)
declare -A x_map=([k]=v)

eq "typeof var int" "int" "$(typeof x_int)"
eq "typeof var float" "float" "$(typeof x_float)"
eq "typeof var bool" "bool" "$(typeof x_bool)"
eq "typeof var char" "char" "$(typeof x_char)"
eq "typeof var str" "str" "$(typeof x_str)"
eq "typeof var empty" "empty" "$(typeof x_empty)"
eq "typeof var list" "list" "$(typeof x_arr)"
eq "typeof var map" "map" "$(typeof x_map)"

section "defined / missed / empty / filled"

defined_var=""
filled_var="value"
unset missing_var 2>/dev/null || true

rc_ok "defined empty var" defined defined_var
rc_ok "defined filled var" defined filled_var
rc_no "defined missing var rejects" defined missing_var

rc_no "missed existing empty var rejects" missed defined_var
rc_no "missed existing filled var rejects" missed filled_var
rc_ok "missed missing var accepts" missed missing_var

rc_ok "empty empty value" empty ""
rc_no "empty filled value rejects" empty "x"
rc_ok "filled value" filled "x"
rc_no "filled empty rejects" filled ""

section "default / coalesce / not"

eq "default keeps filled" "hello" "$(default "hello" "fallback")"
eq "default uses fallback" "fallback" "$(default "" "fallback")"
eq "default empty fallback" "" "$(default "" "")"
eq "default preserves spaces" "  x  " "$(default "  x  " "fallback")"

eq "coalesce first" "a" "$(coalesce "a" "b" "c")"
eq "coalesce skips empty" "b" "$(coalesce "" "" "b" "c")"
eq "coalesce preserves spaces" "  b  " "$(coalesce "" "  b  " "c")"
rc_no "coalesce all empty fails" coalesce "" "" ""

rc_ok "not false command" not false
rc_no "not true command" not true
rc_ok "not is_true false" not is_true false
rc_no "not is_true true" not is_true true

section "assertions"

rc_ok "assert_eq equal" assert_eq "a" "a"
rc_no "assert_eq different fails" assert_eq "a" "b"

rc_ok "assert_ne different" assert_ne "a" "b"
rc_no "assert_ne equal fails" assert_ne "a" "a"

section "use loader"

tmp_root="$(mktemp -d 2>/dev/null || printf '/tmp/cast-daily-test-%s-%s' "$$" "${RANDOM:-0}")"
mkdir -p "${tmp_root}/alpha/beta" "${tmp_root}/gamma"

cat > "${tmp_root}/alpha/beta.sh" <<'EOF'
ALPHA_BETA_LOADED=$(( ${ALPHA_BETA_LOADED:-0} + 1 ))
alpha_beta_value () { printf 'alpha-beta'; }
EOF

cat > "${tmp_root}/gamma/mod.sh" <<'EOF'
GAMMA_LOADED=$(( ${GAMMA_LOADED:-0} + 1 ))
gamma_value () { printf 'gamma'; }
EOF

SOURCE_DIR="${tmp_root}"

rc_ok_silent "use file module silent" use alpha::beta
eq "use file function works" "alpha-beta" "$(alpha_beta_value)"
eq "use file loaded once initial" "1" "${ALPHA_BETA_LOADED:-0}"

rc_ok_silent "use file module second time silent" use alpha::beta
eq "use file loaded once after repeat" "1" "${ALPHA_BETA_LOADED:-0}"

rc_ok_silent "use dir mod module silent" use gamma
eq "use dir function works" "gamma" "$(gamma_value)"
eq "use dir loaded once initial" "1" "${GAMMA_LOADED:-0}"

rc_ok_silent "use dir mod second time silent" use gamma
eq "use dir loaded once after repeat" "1" "${GAMMA_LOADED:-0}"

rc_no "use missing module fails" use missing::module
rc_no "use empty module fails" use ""

cat > "${tmp_root}/cycle_a.sh" <<'EOF'
use cycle_b
EOF

cat > "${tmp_root}/cycle_b.sh" <<'EOF'
use cycle_a
EOF

rc_no "circular use detected" use cycle_a

rm -rf "${tmp_root}" 2>/dev/null || true

section "subshell integration / source order"

eq "source cast then daily typeof" "int" "$(run typeof 123)"
eq "source cast then daily default" "fallback" "$(run default "" fallback)"

section "result"

printf '\npass: %s\n' "${pass}"
printf 'fail: %s\n' "${fail}"

(( fail == 0 ))

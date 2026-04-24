#!/usr/bin/env bash
# shellcheck shell=bash

set -u
set -o pipefail

TARGET="${1:-tool/parts/builtin/list.sh}"

PASS=0
FAIL=0
TOTAL=0

red=""
green=""
yellow=""
reset=""

if [[ -t 1 ]]; then
    red=$'\033[31m'
    green=$'\033[32m'
    yellow=$'\033[33m'
    reset=$'\033[0m'
fi

fail () {

    local name="${1:-}" want="${2:-}" got="${3:-}"

    FAIL=$(( FAIL + 1 ))
    TOTAL=$(( TOTAL + 1 ))

    printf '%s[FAIL]%s %s\n' "${red}" "${reset}" "${name}"
    printf '  want: [%s]\n' "${want}"
    printf '  got : [%s]\n' "${got}"

}

pass () {

    local name="${1:-}"

    PASS=$(( PASS + 1 ))
    TOTAL=$(( TOTAL + 1 ))

    printf '%s[PASS]%s %s\n' "${green}" "${reset}" "${name}"

}

eq () {

    local name="${1:-}" want="${2:-}" got="${3:-}"

    if [[ "${got}" == "${want}" ]]; then
        pass "${name}"
    else
        fail "${name}" "${want}" "${got}"
    fi

}

ok () {

    local name="${1:-}"
    shift || true

    if "$@"; then
        pass "${name}"
    else
        fail "${name}" "exit=0" "exit=$?"
    fi

}

no () {

    local name="${1:-}"
    shift || true

    if "$@"; then
        fail "${name}" "exit!=0" "exit=0"
    else
        pass "${name}"
    fi

}

out () {

    "$@"

}

rc () {

    "$@" >/dev/null 2>&1

}

section () {

    printf '\n%s== %s ==%s\n' "${yellow}" "${1:-}" "${reset}"

}

dump () {

    local name="${1:-}" item=""

    local -n ref="${name}"

    for item in "${ref[@]}"; do
        printf '<%s>\n' "${item}"
    done

}

same_list () {

    local name="${1:-}" want="${2:-}" got=""

    got="$(dump "${name}")"
    eq "${name}" "${want}" "${got}"

}

if [[ ! -r "${TARGET}" ]]; then
    printf '%s[ERR]%s target not readable: %s\n' "${red}" "${reset}" "${TARGET}" >&2
    exit 2
fi

# shellcheck source=/dev/null
source "${TARGET}"

section "existence / public api"

required=(
    list::init
    list::valid
    list::len
    list::has
    list::count
    list::empty
    list::filled
    list::push
    list::pop
    list::unshift
    list::shift
    list::clear
    list::get
    list::set
    list::put
    list::insert
    list::first
    list::last
    list::index
    list::last_index
    list::remove
    list::remove_at
    list::remove_first
    list::remove_last
    list::replace
    list::replace_first
    list::replace_last
    list::concat
    list::copy
    list::slice
    list::reverse
    list::reversed
    list::unique
    list::sort
    list::each
    list::map
    list::filter
    list::all
    list::any
    list::none
    list::from
    list::from_lines
    list::from_args
    list::join
    list::print
    list::args
)

for fn in "${required[@]}"; do
    ok "function exists: ${fn}" declare -F "${fn}"
done

section "init / valid / invalid names"

unset arr scalar __bad 2>/dev/null || true

ok "init creates array" rc list::init arr
ok "valid existing array" rc list::valid arr
eq "init len empty" "0" "$(out list::len arr)"
ok "empty true" rc list::empty arr
no "filled false" rc list::filled arr

scalar="x"
no "valid scalar false" rc list::valid scalar
no "init scalar false" rc list::init scalar
no "init invalid empty" rc list::init ""
no "init invalid starts digit" rc list::init "1abc"
no "init invalid dash" rc list::init "bad-name"
no "valid missing false" rc list::valid missing_array_name

section "push / len / empty / filled / count / has"

list::from_args items "a" "b" "a" "" "c" ""

eq "len initial" "6" "$(out list::len items)"
no "empty false" rc list::empty items
ok "filled true" rc list::filled items
ok "has b" rc list::has items "b"
ok "has empty item" rc list::has items ""
no "has z false" rc list::has items "z"
eq "count a" "2" "$(out list::count items "a")"
eq "count empty" "2" "$(out list::count items "")"
eq "count missing" "0" "$(out list::count items "z")"

list::push items "x" "y z" "*"
same_list items $'<a>\n<b>\n<a>\n<>\n<c>\n<>\n<x>\n<y z>\n<*>'

section "first / last / get"

eq "first value" "a" "$(out list::first items)"
eq "last value" "*" "$(out list::last items)"
eq "first default ignored" "a" "$(out list::first items DEF)"
eq "last default ignored" "*" "$(out list::last items DEF)"

empty_list=()
eq "first empty default" "DEF" "$(out list::first empty_list DEF)"
eq "last empty default" "DEF" "$(out list::last empty_list DEF)"
eq "get 0" "a" "$(out list::get items 0)"
eq "get 1" "b" "$(out list::get items 1)"
eq "get -1" "*" "$(out list::get items -1)"
eq "get -2" "y z" "$(out list::get items -2)"
eq "get bad index default" "DEF" "$(out list::get items abc DEF)"
eq "get out default" "DEF" "$(out list::get items 999 DEF)"
eq "get negative out default" "DEF" "$(out list::get items -999 DEF)"

section "set / put / insert"

list::from_args a "zero" "one" "two"

ok "set middle" rc list::set a 1 "ONE"
same_list a $'<zero>\n<ONE>\n<two>'

ok "set negative last" rc list::set a -1 "TWO"
same_list a $'<zero>\n<ONE>\n<TWO>'

no "set index == len fails" rc list::set a 3 "THREE"
no "set out fails" rc list::set a 99 "x"
no "set bad index fails" rc list::set a x "x"

ok "put index == len appends sparse-safe" rc list::put a 3 "THREE"
same_list a $'<zero>\n<ONE>\n<TWO>\n<THREE>'

ok "put existing replaces" rc list::put a 0 "ZERO"
same_list a $'<ZERO>\n<ONE>\n<TWO>\n<THREE>'

no "put gap fails" rc list::put a 9 "NINE"
no "put negative fails" rc list::put a -1 "x"

ok "insert middle multiple" rc list::insert a 2 "x" "y"
same_list a $'<ZERO>\n<ONE>\n<x>\n<y>\n<TWO>\n<THREE>'

ok "insert start" rc list::insert a 0 "START"
same_list a $'<START>\n<ZERO>\n<ONE>\n<x>\n<y>\n<TWO>\n<THREE>'

ok "insert end" rc list::insert a 7 "END"
same_list a $'<START>\n<ZERO>\n<ONE>\n<x>\n<y>\n<TWO>\n<THREE>\n<END>'

ok "insert negative before last" rc list::insert a -1 "BEFORE_END"
same_list a $'<START>\n<ZERO>\n<ONE>\n<x>\n<y>\n<TWO>\n<THREE>\n<BEFORE_END>\n<END>'

no "insert bad index fails" rc list::insert a zz "x"
no "insert out positive fails" rc list::insert a 99 "x"
no "insert out negative fails" rc list::insert a -99 "x"

section "pop / shift / unshift / clear"

list::from_args q "a" "b" "c"

pop_value=""
ok "pop into target" rc list::pop q pop_value
eq "pop target value" "c" "${pop_value}"
same_list q $'<a>\n<b>'

pop_value=""
ok "pop into target again" rc list::pop q pop_value
eq "pop target value again" "b" "${pop_value}"
same_list q '<a>'

shift_value=""
ok "shift into target" rc list::shift q shift_value
eq "shift target value" "a" "${shift_value}"
same_list q ""

no "pop empty fails" rc list::pop q
no "shift empty fails" rc list::shift q

list::from_args q "b" "c"
ok "unshift multiple" rc list::unshift q "a" ""
same_list q $'<a>\n<>\n<b>\n<c>'

shift_value=""
ok "shift into target again" rc list::shift q shift_value
eq "shift target value again" "a" "${shift_value}"
same_list q $'<>\n<b>\n<c>'

no "pop invalid target fails" rc list::pop q "bad-name"
no "shift invalid target fails" rc list::shift q "bad-name"

ok "clear list" rc list::clear q
eq "clear len zero" "0" "$(out list::len q)"
same_list q ""

section "index / last_index / remove_at"

list::from_args idx "a" "b" "a" "" "c" "a" ""

eq "index first a" "0" "$(out list::index idx "a")"
eq "last_index a" "5" "$(out list::last_index idx "a")"
eq "index empty" "3" "$(out list::index idx "")"
eq "last_index empty" "6" "$(out list::last_index idx "")"
no "index missing fails" rc list::index idx "z"
no "last_index missing fails" rc list::last_index idx "z"

removed=""
ok "remove_at target" rc list::remove_at idx 1 removed
eq "remove_at target value" "b" "${removed}"
same_list idx $'<a>\n<a>\n<>\n<c>\n<a>\n<>'

removed=""
ok "remove_at negative target" rc list::remove_at idx -1 removed
eq "remove_at target value empty" "" "${removed}"
same_list idx $'<a>\n<a>\n<>\n<c>\n<a>'

no "remove_at out fails" rc list::remove_at idx 99
no "remove_at bad index fails" rc list::remove_at idx x
no "remove_at invalid target fails" rc list::remove_at idx 0 "bad-name"

section "remove / remove_first / remove_last"

list::from_args r "a" "b" "a" "" "c" "a" ""

ok "remove all a" rc list::remove r "a"
same_list r $'<b>\n<>\n<c>\n<>'

ok "remove all empty" rc list::remove r ""
same_list r $'<b>\n<c>'

list::from_args r "a" "b" "a" "c" "a"

ok "remove_first a" rc list::remove_first r "a"
same_list r $'<b>\n<a>\n<c>\n<a>'

ok "remove_last a" rc list::remove_last r "a"
same_list r $'<b>\n<a>\n<c>'

no "remove_first missing fails" rc list::remove_first r "z"
no "remove_last missing fails" rc list::remove_last r "z"

section "replace / replace_first / replace_last"

list::from_args rp "a" "b" "a" "" "a"

ok "replace all a" rc list::replace rp "a" "x"
same_list rp $'<x>\n<b>\n<x>\n<>\n<x>'

ok "replace empty" rc list::replace rp "" "EMPTY"
same_list rp $'<x>\n<b>\n<x>\n<EMPTY>\n<x>'

no "replace missing fails" rc list::replace rp "z" "q"

list::from_args rp "a" "b" "a" "c" "a"
ok "replace_first" rc list::replace_first rp "a" "FIRST"
same_list rp $'<FIRST>\n<b>\n<a>\n<c>\n<a>'

ok "replace_last" rc list::replace_last rp "a" "LAST"
same_list rp $'<FIRST>\n<b>\n<a>\n<c>\n<LAST>'

no "replace_first missing fails" rc list::replace_first rp "z" "x"
no "replace_last missing fails" rc list::replace_last rp "z" "x"

section "concat / copy / slice"

list::from_args left "a" "b"
list::from_args right "c" "" "d"

ok "concat" rc list::concat left right
same_list left $'<a>\n<b>\n<c>\n<>\n<d>'
same_list right $'<c>\n<>\n<d>'

ok "copy" rc list::copy left copied
same_list copied $'<a>\n<b>\n<c>\n<>\n<d>'

list::set copied 0 "CHANGED"
same_list left $'<a>\n<b>\n<c>\n<>\n<d>'
same_list copied $'<CHANGED>\n<b>\n<c>\n<>\n<d>'

ok "slice from 1 count 3" rc list::slice left sliced 1 3
same_list sliced $'<b>\n<c>\n<>'

ok "slice negative start" rc list::slice left sliced2 -2
same_list sliced2 $'<>\n<d>'

ok "slice start beyond len empty" rc list::slice left sliced3 99
same_list sliced3 ""

ok "slice negative far clamps zero" rc list::slice left sliced4 -99 2
same_list sliced4 $'<a>\n<b>'

no "slice bad target fails" rc list::slice left "bad-name" 0
no "slice bad start fails" rc list::slice left out x
no "slice bad count fails" rc list::slice left out 0 -1

section "reverse / reversed"

list::from_args rev "a" "b" "" "c"

ok "reverse in-place" rc list::reverse rev
same_list rev $'<c>\n<>\n<b>\n<a>'

ok "reversed copy" rc list::reversed rev rev2
same_list rev $'<c>\n<>\n<b>\n<a>'
same_list rev2 $'<a>\n<b>\n<>\n<c>'

ok "reverse empty" rc list::reverse empty_list
same_list empty_list ""

no "reversed bad target fails" rc list::reversed rev "bad-name"

section "unique"

list::from_args u "a" "" "b" "a" "" "c" "b" ""

ok "unique preserves first occurrence including empty" rc list::unique u
same_list u $'<a>\n<>\n<b>\n<c>'

list::from_args u2 "" "" ""
ok "unique all empty" rc list::unique u2
same_list u2 '<>'

section "sort"

list::from_args s "b" "a" "c" "a"

ok "sort asc" rc list::sort s
same_list s $'<a>\n<a>\n<b>\n<c>'

ok "sort desc" rc list::sort s desc
same_list s $'<c>\n<b>\n<a>\n<a>'

no "sort bad order fails" rc list::sort s weird

section "join / print / args"

list::from_args j "a" "" "b c" "*"

eq "join comma" "a,,b c,*" "$(out list::join j ",")"
eq "join empty sep" "ab c*" "$(out list::join j "")"
eq "print lines" $'a\n\nb c\n*' "$(out list::print j)"
eq "args alias lines" $'a\n\nb c\n*' "$(out list::args j)"

empty_print=()
eq "print empty no output" "" "$(out list::print empty_print)"
eq "args empty no output" "" "$(out list::args empty_print)"

section "from / from_args / from_lines"

list::from_args fa "one two" "" "*" "end"
same_list fa $'<one two>\n<>\n<*>\n<end>'

ok "from comma" rc list::from ff "a,,b," ","
same_list ff $'<a>\n<>\n<b>\n<>'

ok "from multi sep" rc list::from fm "a--b----c--" "--"
same_list fm $'<a>\n<b>\n<>\n<c>\n<>'

ok "from default newline" rc list::from fl $'a\n\nb\n'
same_list fl $'<a>\n<>\n<b>\n<>'

ok "from empty string gives one empty item" rc list::from fe "" ","
same_list fe '<>'

no "from empty separator fails" rc list::from bad "a,b" ""

list::from_lines stdin_lines < <(printf '%s\n' "alpha" "" "beta gamma")
same_list stdin_lines $'<alpha>\n<>\n<beta gamma>'

list::from_lines no_final_newline < <(printf '%s' "no-final-newline")
same_list no_final_newline '<no-final-newline>'

section "callbacks each / map / filter / all / any / none"

cb_seen=()

cb_collect () {

    cb_seen+=( "$1" )

}

cb_upper () {

    printf '%s' "${1^^}"

}

cb_nonempty () {

    [[ -n "${1:-}" ]]

}

cb_is_a () {

    [[ "${1:-}" == "a" ]]

}

cb_never () {

    return 1

}

cb_fail_on_b () {

    [[ "${1:-}" != "b" ]]

}

list::from_args cb "a" "b" "" "c"

ok "each collect" rc list::each cb cb_collect
same_list cb_seen $'<a>\n<b>\n<>\n<c>'

no "each stops on failure" rc list::each cb cb_fail_on_b

ok "map upper" rc list::map cb mapped cb_upper
same_list mapped $'<A>\n<B>\n<>\n<C>'

ok "filter nonempty" rc list::filter cb filtered cb_nonempty
same_list filtered $'<a>\n<b>\n<c>'

no "missing callback each fails" rc list::each cb missing_callback
no "missing callback map fails" rc list::map cb out_missing missing_callback
no "missing callback filter fails" rc list::filter cb out_missing missing_callback

list::from_args all_ok a b c
ok "all nonempty true" rc list::all all_ok cb_nonempty

no "all nonempty false" rc list::all cb cb_nonempty
ok "any is a true" rc list::any cb cb_is_a
no "any missing false" rc list::any cb cb_never

list::from_args none_ok b c
ok "none missing true" rc list::none none_ok cb_is_a

no "none is a false" rc list::none cb cb_is_a

section "failure paths / non arrays"

bad_scalar="x"

no "len scalar fails" rc list::len bad_scalar
no "push scalar fails" rc list::push bad_scalar x
no "get scalar fails" rc list::get bad_scalar 0
no "set scalar fails" rc list::set bad_scalar 0 x
no "insert scalar fails" rc list::insert bad_scalar 0 x
no "remove scalar fails" rc list::remove bad_scalar x
no "concat scalar fails" rc list::concat bad_scalar cb
no "copy bad target fails" rc list::copy cb "bad-name"

section "property / invariants"

list::from_args prop "  a  " "" "b/c" "*" "z z"

before="$(out list::join prop $'\037')"
ok "reverse twice returns original" rc list::reverse prop
ok "reverse twice second" rc list::reverse prop
after="$(out list::join prop $'\037')"
eq "reverse twice invariant" "${before}" "${after}"

ok "copy then join equal" rc list::copy prop prop_copy
eq "copy content invariant" "$(out list::join prop $'\037')" "$(out list::join prop_copy $'\037')"

ok "slice full equals original" rc list::slice prop prop_slice 0
eq "slice full invariant" "$(out list::join prop $'\037')" "$(out list::join prop_slice $'\037')"

section "self reference safety"

list::from_args self_copy "a" "b" "c"
ok "copy to self preserves" rc list::copy self_copy self_copy
same_list self_copy $'<a>\n<b>\n<c>'

list::from_args self_slice "a" "b" "c"
ok "slice to self preserves selected" rc list::slice self_slice self_slice 1
same_list self_slice $'<b>\n<c>'

list::from_args self_map "a" "b" ""
ok "map to self works" rc list::map self_map self_map cb_upper
same_list self_map $'<A>\n<B>\n<>'

list::from_args self_filter "a" "" "b"
ok "filter to self works" rc list::filter self_filter self_filter cb_nonempty
same_list self_filter $'<a>\n<b>'

list::from_args self_concat "a" "b"
ok "concat self duplicates once" rc list::concat self_concat self_concat
same_list self_concat $'<a>\n<b>\n<a>\n<b>'

printf '\n%s== result ==%s\n' "${yellow}" "${reset}"
printf 'total: %s\n' "${TOTAL}"
printf '%spass : %s%s\n' "${green}" "${PASS}" "${reset}"
printf '%sfail : %s%s\n' "${red}" "${FAIL}" "${reset}"

if (( FAIL > 0 )); then
    exit 1
fi

exit 0

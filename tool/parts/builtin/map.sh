# shellcheck shell=bash
# shellcheck disable=SC2178,SC2034

map::init () {

    local name="${1:-}" decl=""

    [[ "${name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1

    if ! declare -p "${name}" >/dev/null 2>&1; then
        declare -g -A "${name}=()"
        return 0
    fi

    decl="$(declare -p "${name}" 2>/dev/null)" || return 1

    [[ "${decl}" =~ ^declare\ -[a-zA-Z]*A[a-zA-Z]*[[:space:]] ]]

}
map::valid () {

    local name="${1:-}" decl=""

    [[ "${name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1
    decl="$(declare -p "${name}" 2>/dev/null)" || return 1

    [[ "${decl}" =~ ^declare\ -[a-zA-Z]*A[a-zA-Z]*[[:space:]] ]]

}
map::len () {

    local name="${1:-}"

    map::init "${name}" || return 1

    local -n ref="${name}"
    printf '%s\n' "${#ref[@]}"

}
map::empty () {

    local name="${1:-}"

    map::init "${name}" || return 1

    local -n ref="${name}"
    (( ${#ref[@]} == 0 ))

}
map::filled () {

    local name="${1:-}"

    map::init "${name}" || return 1

    local -n ref="${name}"
    (( ${#ref[@]} > 0 ))

}

map::has () {

    local name="${1:-}" key="${2-}"

    map::init "${name}" || return 1
    [[ -n "${key}" ]] || return 1

    local -n ref="${name}"
    [[ -v "ref[$key]" ]]

}
map::get () {

    local name="${1:-}" key="${2-}" def="${3-}"

    map::init "${name}" || return 1
    [[ -n "${key}" ]] || { printf '%s' "${def}"; return 0; }

    local -n ref="${name}"

    if [[ -v "ref[$key]" ]]; then printf '%s' "${ref[$key]}"
    else printf '%s' "${def}"
    fi

}
map::set () {

    local name="${1:-}" key="${2-}" value="${3-}"

    map::init "${name}" || return 1
    [[ -n "${key}" ]] || return 1

    local -n ref="${name}"
    ref["${key}"]="${value}"

}
map::del () {

    local name="${1:-}" key="${2-}"

    map::init "${name}" || return 1
    [[ -n "${key}" ]] || return 1

    local -n ref="${name}"

    [[ -v "ref[$key]" ]] || return 1
    unset 'ref[$key]'

}
map::put () {

    map::set "$@"

}
map::delete () {

    map::del "$@"

}
map::set_once () {

    local name="${1:-}" key="${2-}" value="${3-}"

    map::init "${name}" || return 1
    [[ -n "${key}" ]] || return 1

    local -n ref="${name}"

    [[ -v "ref[$key]" ]] && return 0
    ref["${key}"]="${value}"

}
map::replace () {

    local name="${1:-}" key="${2-}" value="${3-}"

    map::init "${name}" || return 1
    [[ -n "${key}" ]] || return 1

    local -n ref="${name}"

    [[ -v "ref[$key]" ]] || return 1
    ref["${key}"]="${value}"

}
map::clear () {

    local name="${1:-}"

    map::init "${name}" || return 1

    local -n ref="${name}"
    ref=()

}

map::keys0 () {

    local name="${1:-}"

    map::init "${name}" || return 1

    local -n ref="${name}"
    (( ${#ref[@]} > 0 )) || return 0

    if command -v sort >/dev/null 2>&1 && printf 'x\0' | LC_ALL=C sort -z >/dev/null 2>&1; then
        printf '%s\0' "${!ref[@]}" | LC_ALL=C sort -z
    else
        printf '%s\0' "${!ref[@]}"
    fi

}
map::values0 () {

    local name="${1:-}" key=""

    map::init "${name}" || return 1

    local -n ref="${name}"

    while IFS= read -r -d '' key; do
        printf '%s\0' "${ref[$key]}"
    done < <(map::keys0 "${name}")

}
map::items0 () {

    local name="${1:-}" key=""

    map::init "${name}" || return 1

    local -n ref="${name}"

    while IFS= read -r -d '' key; do
        printf '%s\0%s\0' "${key}" "${ref[$key]}"
    done < <(map::keys0 "${name}")

}
map::keys () {

    local name="${1:-}" key=""

    map::init "${name}" || return 1

    while IFS= read -r -d '' key; do
        printf '%s\n' "${key}"
    done < <(map::keys0 "${name}")

}
map::values () {

    local name="${1:-}" key=""

    map::init "${name}" || return 1

    local -n ref="${name}"

    while IFS= read -r -d '' key; do
        printf '%s\n' "${ref[$key]}"
    done < <(map::keys0 "${name}")

}
map::items () {

    local name="${1:-}" key=""

    map::init "${name}" || return 1

    local -n ref="${name}"

    while IFS= read -r -d '' key; do
        printf '%s\t%s\n' "${key}" "${ref[$key]}"
    done < <(map::keys0 "${name}")

}

map::merge () {

    local name="${1:-}" other="${2:-}" key=""
    local -a keys=()
    local -a values=()

    map::init "${name}"  || return 1
    map::init "${other}" || return 1

    local -n dst="${name}"
    local -n src="${other}"

    for key in "${!src[@]}"; do
        keys+=( "${key}" )
        values+=( "${src[$key]}" )
    done

    for key in "${!keys[@]}"; do
        dst["${keys[$key]}"]="${values[$key]}"
    done

}
map::concat () {

    map::merge "$@"

}
map::copy () {

    local from="${1:-}" to="${2:-}" key=""
    local -a keys=()
    local -a values=()

    map::init "${from}" || return 1
    [[ "${to}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1

    local -n src="${from}"

    for key in "${!src[@]}"; do
        keys+=( "${key}" )
        values+=( "${src[$key]}" )
    done

    declare -g -A "${to}=()"
    local -n dst="${to}"

    for key in "${!keys[@]}"; do
        dst["${keys[$key]}"]="${values[$key]}"
    done

}
map::only () {

    local name="${1:-}" target="${2:-}" key=""
    local -a keys=()
    local -a values=()

    map::init "${name}" || return 1

    [[ "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1
    shift 2 || true

    local -n src="${name}"

    for key in "$@"; do

        [[ -n "${key}" ]] || continue
        [[ -v "src[$key]" ]] || continue

        keys+=( "${key}" )
        values+=( "${src[$key]}" )

    done

    declare -g -A "${target}=()"
    local -n dst="${target}"

    for key in "${!keys[@]}"; do
        dst["${keys[$key]}"]="${values[$key]}"
    done

}
map::without () {

    local name="${1:-}" target="${2:-}"
    shift 2 || true

    map::copy "${name}" "${target}" || return 1

    local -n dst="${target}"
    local key=""

    for key in "$@"; do
        [[ -n "${key}" ]] || continue
        unset 'dst[$key]'
    done

}

map::each () {

    local name="${1:-}" fn="${2:-}" key=""

    map::init "${name}" || return 1
    declare -F "${fn}" >/dev/null 2>&1 || return 1

    local -n ref="${name}"

    while IFS= read -r -d '' key; do
        "${fn}" "${key}" "${ref[$key]}" || return
    done < <(map::keys0 "${name}")

}
map::map () {

    local name="${1:-}" target="${2:-}" fn="${3:-}" key="" value=""
    local -a keys=()
    local -a values=()

    map::init "${name}" || return 1

    [[ "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1
    declare -F "${fn}" >/dev/null 2>&1 || return 1

    local -n src="${name}"

    for key in "${!src[@]}"; do
        keys+=( "${key}" )
        values+=( "${src[$key]}" )
    done

    declare -g -A "${target}=()"
    local -n dst="${target}"

    for key in "${!keys[@]}"; do
        value="$("${fn}" "${keys[$key]}" "${values[$key]}")" || return
        dst["${keys[$key]}"]="${value}"
    done

}
map::filter () {

    local name="${1:-}" target="${2:-}" fn="${3:-}" key=""
    local -a keys=()
    local -a values=()

    map::init "${name}" || return 1

    [[ "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1
    declare -F "${fn}" >/dev/null 2>&1 || return 1

    local -n src="${name}"

    for key in "${!src[@]}"; do
        keys+=( "${key}" )
        values+=( "${src[$key]}" )
    done

    declare -g -A "${target}=()"
    local -n dst="${target}"

    for key in "${!keys[@]}"; do

        if "${fn}" "${keys[$key]}" "${values[$key]}"; then
            dst["${keys[$key]}"]="${values[$key]}"
        fi

    done

}
map::all () {

    local name="${1:-}" fn="${2:-}" key=""

    map::init "${name}" || return 1
    declare -F "${fn}" >/dev/null 2>&1 || return 1

    local -n ref="${name}"

    for key in "${!ref[@]}"; do
        "${fn}" "${key}" "${ref[$key]}" || return 1
    done

    return 0

}
map::any () {

    local name="${1:-}" fn="${2:-}" key=""

    map::init "${name}" || return 1
    declare -F "${fn}" >/dev/null 2>&1 || return 1

    local -n ref="${name}"

    for key in "${!ref[@]}"; do
        "${fn}" "${key}" "${ref[$key]}" && return 0
    done

    return 1

}
map::none () {

    ! map::any "$@"

}

map::print () {

    map::items "$@"

}
map::str () {

    local name="${1:-}" item_sep="${2-$'\n'}" pair_sep="${3-=}" key="" out="" first=1

    map::init "${name}" || return 1
    [[ -n "${item_sep}" && -n "${pair_sep}" ]] || return 1

    local -n ref="${name}"

    while IFS= read -r -d '' key; do

        if (( first )); then first=0
        else out+="${item_sep}"
        fi

        out+="${key}${pair_sep}${ref[$key]}"

    done < <(map::keys0 "${name}")

    printf '%s' "${out}"

}

map::from () {

    local name="${1:-}" s="${2:-}" item_sep="${3-$'\n'}" pair_sep="${4-=}" item="" key="" value="" i=0
    local -a keys=()
    local -a values=()

    [[ "${name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1
    [[ -n "${item_sep}" && -n "${pair_sep}" ]] || return 1

    while [[ "${s}" == *"${item_sep}"* ]]; do

        item="${s%%"${item_sep}"*}"
        s="${s#*"${item_sep}"}"

        [[ "${item}" == *"${pair_sep}"* ]] || continue

        key="${item%%"${pair_sep}"*}"
        value="${item#*"${pair_sep}"}"

        [[ -n "${key}" ]] || return 1
        keys+=( "${key}" )
        values+=( "${value}" )

    done

    item="${s}"

    if [[ "${item}" == *"${pair_sep}"* ]]; then

        key="${item%%"${pair_sep}"*}"
        value="${item#*"${pair_sep}"}"

        [[ -n "${key}" ]] || return 1
        keys+=( "${key}" )
        values+=( "${value}" )

    fi

    declare -g -A "${name}=()"
    local -n ref="${name}"

    for (( i=0; i<${#keys[@]}; i++ )); do
        ref["${keys[$i]}"]="${values[$i]}"
    done

}
map::from_pairs () {

    local name="${1:-}" key="" value="" i=0
    local -a keys=()
    local -a values=()

    [[ "${name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1
    shift || true

    (( $# % 2 == 0 )) || return 1

    while (( $# > 0 )); do

        key="${1-}"
        value="${2-}"

        [[ -n "${key}" ]] || return 1
        keys+=( "${key}" )
        values+=( "${value}" )

        shift 2 || true

    done

    declare -g -A "${name}=()"
    local -n ref="${name}"

    for (( i=0; i<${#keys[@]}; i++ )); do
        ref["${keys[$i]}"]="${values[$i]}"
    done

}
map::from_lines () {

    local name="${1:-}" sep="${2-=}" line="" key="" value="" i=0
    local -a keys=()
    local -a values=()

    [[ "${name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1
    [[ -n "${sep}" ]] || return 1

    while IFS= read -r line || [[ -n "${line}" ]]; do

        [[ "${line}" == *"${sep}"* ]] || continue

        key="${line%%"${sep}"*}"
        value="${line#*"${sep}"}"

        [[ -n "${key}" ]] || return 1
        keys+=( "${key}" )
        values+=( "${value}" )

    done

    declare -g -A "${name}=()"
    local -n ref="${name}"

    for (( i=0; i<${#keys[@]}; i++ )); do
        ref["${keys[$i]}"]="${values[$i]}"
    done

}

# shellcheck disable=SC2178

list::init () {

    local name="${1:-}" decl=""

    [[ "${name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1

    if ! declare -p "${name}" >/dev/null 2>&1; then
        declare -g -a "${name}=()"
        return 0
    fi

    decl="$(declare -p "${name}" 2>/dev/null)" || return 1

    [[ "${decl}" =~ ^declare\ -[a-zA-Z]*a[a-zA-Z]*[[:space:]] ]]

}
list::valid () {

    local name="${1:-}" decl=""

    [[ "${name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1
    decl="$(declare -p "${name}" 2>/dev/null)" || return 1

    [[ "${decl}" =~ ^declare\ -[a-zA-Z]*a[a-zA-Z]*[[:space:]] ]]

}
list::len () {

    local name="${1:-}"

    list::init "${name}" || return 1

    local -n ref="${name}"
    printf '%s\n' "${#ref[@]}"

}
list::has () {

    local name="${1:-}" needle="${2:-}"
    list::index "${name}" "${needle}" >/dev/null

}
list::count () {

    local name="${1:-}" needle="${2:-}" x="" n=0

    list::init "${name}" || return 1
    local -n ref="${name}"

    for x in "${ref[@]}"; do
        [[ "${x}" == "${needle}" ]] && n=$(( n + 1 ))
    done

    printf '%s\n' "${n}"

}
list::empty () {

    local name="${1:-}"

    list::init "${name}" || return 1

    local -n ref="${name}"
    (( ${#ref[@]} == 0 ))

}
list::filled () {

    local name="${1:-}"

    list::init "${name}" || return 1

    local -n ref="${name}"
    (( ${#ref[@]} > 0 ))

}

list::push () {

    local name="${1:-}"

    list::init "${name}" || return 1
    shift || true

    local -n ref="${name}"
    ref+=( "$@" )

}
list::pop () {

    local name="${1:-}" target="${2:-}" last=0 value=""

    list::init "${name}" || return 1
    [[ -z "${target}" || "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1

    local -n ref="${name}"
    (( ${#ref[@]} > 0 )) || return 1

    last=$(( ${#ref[@]} - 1 ))
    value="${ref[$last]}"

    unset 'ref[$last]'

    if [[ -n "${target}" ]]; then printf -v "${target}" '%s' "${value}"
    else printf '%s' "${value}"
    fi

}
list::unshift () {

    local name="${1:-}"

    list::init "${name}" || return 1
    shift || true

    local -n ref="${name}"
    ref=( "$@" "${ref[@]}" )

}
list::shift () {

    local name="${1:-}" target="${2:-}" value=""

    list::init "${name}" || return 1
    [[ -z "${target}" || "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1

    local -n ref="${name}"
    (( ${#ref[@]} > 0 )) || return 1

    value="${ref[0]}"
    ref=( "${ref[@]:1}" )

    if [[ -n "${target}" ]]; then printf -v "${target}" '%s' "${value}"
    else printf '%s' "${value}"
    fi

}
list::clear () {

    local name="${1:-}"

    list::init "${name}" || return 1

    local -n ref="${name}"
    ref=()

}

list::get () {

    local name="${1:-}" index="${2:-}" def="${3:-}"

    list::init "${name}" || return 1
    [[ "${index}" =~ ^-?[0-9]+$ ]] || { printf '%s' "${def}"; return 0; }

    local -n ref="${name}"
    (( index < 0 )) && index=$(( ${#ref[@]} + index ))

    if (( index >= 0 && index < ${#ref[@]} )); then printf '%s' "${ref[$index]}"
    else printf '%s' "${def}"
    fi

}
list::set () {

    local name="${1:-}" index="${2:-}" value="${3:-}"

    list::init "${name}" || return 1
    [[ "${index}" =~ ^-?[0-9]+$ ]] || return 1

    local -n ref="${name}"

    (( index < 0 )) && index=$(( ${#ref[@]} + index ))
    (( index >= 0 && index < ${#ref[@]} )) || return 1

    ref[index]="${value}"

}
list::put () {

    local name="${1:-}" index="${2:-}" value="${3:-}"

    list::init "${name}" || return 1
    [[ "${index}" =~ ^[0-9]+$ ]] || return 1

    local -n ref="${name}"

    (( index <= ${#ref[@]} )) || return 1
    ref[index]="${value}"

}
list::insert () {

    local name="${1:-}" index="${2:-}"

    list::init "${name}" || return 1

    [[ "${index}" =~ ^-?[0-9]+$ ]] || return 1
    shift 2 || true

    local -n ref="${name}"

    (( index < 0 )) && index=$(( ${#ref[@]} + index ))
    (( index >= 0 && index <= ${#ref[@]} )) || return 1

    ref=( "${ref[@]:0:index}" "$@" "${ref[@]:index}" )

}

list::first () {

    local name="${1:-}" def="${2:-}"

    list::init "${name}" || return 1
    local -n ref="${name}"

    if (( ${#ref[@]} > 0 )); then printf '%s' "${ref[0]}"
    else printf '%s' "${def}"
    fi

}
list::last () {

    local name="${1:-}" def="${2:-}" last=0

    list::init "${name}" || return 1
    local -n ref="${name}"

    if (( ${#ref[@]} > 0 )); then last=$(( ${#ref[@]} - 1 )); printf '%s' "${ref[$last]}"
    else printf '%s' "${def}"
    fi

}
list::index () {

    local name="${1:-}" needle="${2:-}" i=0

    list::init "${name}" || return 1
    local -n ref="${name}"

    for (( i=0; i<${#ref[@]}; i++ )); do

        if [[ "${ref[$i]}" == "${needle}" ]]; then
            printf '%s' "${i}"
            return 0
        fi

    done

    return 1

}
list::last_index () {

    local name="${1:-}" needle="${2:-}" i=0

    list::init "${name}" || return 1
    local -n ref="${name}"

    for (( i=${#ref[@]}-1; i>=0; i-- )); do

        if [[ "${ref[$i]}" == "${needle}" ]]; then
            printf '%s' "${i}"
            return 0
        fi

    done

    return 1

}

list::remove () {

    local name="${1:-}" needle="${2:-}" x=""
    local -a out=()

    list::init "${name}" || return 1

    local -n ref="${name}"

    for x in "${ref[@]}"; do
        [[ "${x}" == "${needle}" ]] && continue
        out+=( "${x}" )
    done

    ref=( "${out[@]}" )

}
list::remove_at () {

    local name="${1:-}" index="${2:-}" target="${3:-}" value=""

    list::init "${name}" || return 1
    [[ "${index}" =~ ^-?[0-9]+$ ]] || return 1
    [[ -z "${target}" || "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1

    local -n ref="${name}"

    (( index < 0 )) && index=$(( ${#ref[@]} + index ))
    (( index >= 0 && index < ${#ref[@]} )) || return 1

    value="${ref[$index]}"
    ref=( "${ref[@]:0:index}" "${ref[@]:index+1}" )

    if [[ -n "${target}" ]]; then printf -v "${target}" '%s' "${value}"
    else printf '%s' "${value}"
    fi

}
list::remove_first () {

    local name="${1:-}" needle="${2:-}" x="" done=0
    local -a out=()

    list::init "${name}" || return 1

    local -n ref="${name}"

    for x in "${ref[@]}"; do

        if (( ! done )) && [[ "${x}" == "${needle}" ]]; then
            done=1
            continue
        fi

        out+=( "${x}" )

    done

    ref=( "${out[@]}" )
    (( done ))

}
list::remove_last () {

    local name="${1:-}" needle="${2:-}" index=""

    list::init "${name}" || return 1

    index="$(list::last_index "${name}" "${needle}")" || return 1
    list::remove_at "${name}" "${index}" >/dev/null

}

list::replace () {

    local name="${1:-}" from="${2:-}" to="${3:-}" i=0 changed=0

    list::init "${name}" || return 1

    local -n ref="${name}"

    for (( i=0; i<${#ref[@]}; i++ )); do

        if [[ "${ref[$i]}" == "${from}" ]]; then
            ref[i]="${to}"
            changed=1
        fi

    done

    (( changed ))

}
list::replace_first () {

    local name="${1:-}" from="${2:-}" to="${3:-}" i=0

    list::init "${name}" || return 1

    local -n ref="${name}"

    for (( i=0; i<${#ref[@]}; i++ )); do

        if [[ "${ref[$i]}" == "${from}" ]]; then
            ref[i]="${to}"
            return 0
        fi

    done

    return 1

}
list::replace_last () {

    local name="${1:-}" from="${2:-}" to="${3:-}" i=0

    list::init "${name}" || return 1

    local -n ref="${name}"

    for (( i=${#ref[@]}-1; i>=0; i-- )); do

        if [[ "${ref[$i]}" == "${from}" ]]; then
            ref[i]="${to}"
            return 0
        fi

    done

    return 1

}

list::slice () {

    local name="${1:-}" target="${2:-}" start="${3:-0}" count="${4:-}" len=0
    local -a snapshot=()

    list::init "${name}" || return 1

    [[ "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1
    [[ "${start}" =~ ^-?[0-9]+$ ]] || return 1

    local -n src="${name}"
    snapshot=( "${src[@]}" )

    declare -g -a "${target}=()"
    local -n dst="${target}"

    len="${#snapshot[@]}"

    (( start < 0 )) && start=$(( len + start ))
    (( start < 0 )) && start=0
    (( start > len )) && { dst=(); return 0; }

    if [[ -n "${count}" ]]; then
        [[ "${count}" =~ ^[0-9]+$ ]] || return 1
        dst=( "${snapshot[@]:start:count}" )
    else
        dst=( "${snapshot[@]:start}" )
    fi

}
list::reverse () {

    local name="${1:-}" i=0
    local -a out=()

    list::init "${name}" || return 1

    local -n ref="${name}"

    for (( i=${#ref[@]}-1; i>=0; i-- )); do
        out+=( "${ref[$i]}" )
    done

    ref=( "${out[@]}" )

}
list::reversed () {

    local name="${1:-}" target="${2:-}"

    list::init "${name}" || return 1
    [[ "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1

    list::copy "${name}" "${target}" || return 1
    list::reverse "${target}"

}
list::unique () {

    local name="${1:-}" x="" key=""
    local -A seen=()
    local -a out=()

    list::init "${name}" || return 1
    local -n ref="${name}"

    for x in "${ref[@]}"; do

        key=":${x}"
        [[ -v "seen[$key]" ]] && continue

        seen["${key}"]=1
        out+=( "${x}" )

    done

    ref=( "${out[@]}" )

}
list::sort () {

    local name="${1:-}" order="${2:-asc}"

    list::init "${name}" || return 1
    command -v sort >/dev/null 2>&1 || return 1

    local -n ref="${name}"

    case "${order}" in
        asc|"") mapfile -t ref < <(printf '%s\n' "${ref[@]}" | LC_ALL=C sort) ;;
        desc) mapfile -t ref < <(printf '%s\n' "${ref[@]}" | LC_ALL=C sort -r) ;;
        *) return 1 ;;
    esac

}

list::each () {

    local name="${1:-}" fn="${2:-}" x=""

    list::init "${name}" || return 1
    declare -F "${fn}" >/dev/null 2>&1 || return 1

    local -n ref="${name}"

    for x in "${ref[@]}"; do
        "${fn}" "${x}" || return
    done

}
list::map () {

    local name="${1:-}" target="${2:-}" fn="${3:-}" x="" y=""
    local -a snapshot=()

    list::init "${name}" || return 1

    [[ "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1
    declare -F "${fn}" >/dev/null 2>&1 || return 1

    local -n src="${name}"
    snapshot=( "${src[@]}" )

    declare -g -a "${target}=()"
    local -n dst="${target}"

    for x in "${snapshot[@]}"; do
        y="$("${fn}" "${x}")" || return
        dst+=( "${y}" )
    done

}
list::filter () {

    local name="${1:-}" target="${2:-}" fn="${3:-}" x=""
    local -a snapshot=()

    list::init "${name}" || return 1

    [[ "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1
    declare -F "${fn}" >/dev/null 2>&1 || return 1

    local -n src="${name}"
    snapshot=( "${src[@]}" )

    declare -g -a "${target}=()"
    local -n dst="${target}"

    for x in "${snapshot[@]}"; do
        "${fn}" "${x}" && dst+=( "${x}" )
    done

}
list::all () {

    local name="${1:-}" fn="${2:-}" x=""

    list::init "${name}" || return 1

    declare -F "${fn}" >/dev/null 2>&1 || return 1
    local -n ref="${name}"

    for x in "${ref[@]}"; do
        "${fn}" "${x}" || return 1
    done

    return 0

}
list::any () {

    local name="${1:-}" fn="${2:-}" x=""

    list::init "${name}" || return 1

    declare -F "${fn}" >/dev/null 2>&1 || return 1
    local -n ref="${name}"

    for x in "${ref[@]}"; do
        "${fn}" "${x}" && return 0
    done

    return 1

}
list::none () {

    ! list::any "$@"

}

list::copy () {

    local from="${1:-}" to="${2:-}"

    list::init "${from}" || return 1

    [[ "${to}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1

    local -a snapshot=()
    local -n src="${from}"

    snapshot=( "${src[@]}" )

    declare -g -a "${to}=()"
    local -n dst="${to}"

    dst=( "${snapshot[@]}" )

}
list::concat () {

    local name="${1:-}" other="${2:-}"
    local -a snapshot=()

    list::init "${name}"  || return 1
    list::init "${other}" || return 1

    local -n ref="${name}"
    local -n src="${other}"

    snapshot=( "${src[@]}" )
    ref+=( "${snapshot[@]}" )

}
list::join () {

    local name="${1:-}" sep="${2:-}" result="" item="" first=1

    list::init "${name}" || return 1

    local -n ref="${name}"

    for item in "${ref[@]}"; do

        if (( first )); then result="${item}"; first=0
        else result+="${sep}${item}"
        fi

    done

    printf '%s' "${result}"

}
list::print () {

    local name="${1:-}"
    list::init "${name}" || return 1

    local -n ref="${name}"
    (( ${#ref[@]} > 0 )) || return 0
    printf '%s\n' "${ref[@]}"

}
list::str () {

    local name="${1:-}"
    list::print "${name}"

}

list::from () {

    local name="${1:-}" s="${2:-}" sep="${3-$'\n'}" rest="" pos=""

    [[ "${name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1
    [[ -n "${sep}" ]] || return 1

    declare -g -a "${name}=()"
    local -n ref="${name}"

    rest="${s}"

    while [[ "${rest}" == *"${sep}"* ]]; do

        pos="${rest%%"${sep}"*}"
        ref+=( "${pos}" )
        rest="${rest#*"${sep}"}"

    done

    ref+=( "${rest}" )

}
list::from_lines () {

    local name="${1:-}" line=""

    [[ "${name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1

    declare -g -a "${name}=()"
    local -n ref="${name}"

    while IFS= read -r line || [[ -n "${line}" ]]; do
        ref+=( "${line}" )
    done

}
list::from_args () {

    local name="${1:-}"

    [[ "${name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1
    shift || true

    declare -g -a "${name}=()"
    local -n ref="${name}"

    ref=( "$@" )

}

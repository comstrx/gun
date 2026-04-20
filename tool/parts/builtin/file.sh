

new_file () {

    local path="${1:-}" dir=""
    [[ -n "${path}" ]] || return 1

    dir="$(dir_name "${path}")" || return 1
    command mkdir -p -- "${dir}" || return 1

    : > "${path}"

}
read_file () {

    local path="${1:-}"
    [[ -f "${path}" ]] || return 1

    cat -- "${path}"

}
write_file () {

    local path="${1:-}" data="${2-}" dir=""
    [[ -n "${path}" ]] || return 1

    dir="$(dir_name "${path}")" || return 1
    command mkdir -p -- "${dir}" || return 1

    printf '%s' "${data}" > "${path}"

}
append_file () {

    local path="${1:-}" data="${2-}" dir=""
    [[ -n "${path}" ]] || return 1

    dir="$(dir_name "${path}")" || return 1
    command mkdir -p -- "${dir}" || return 1

    printf '%s' "${data}" >> "${path}"

}

file_name () {

    local path="${1:-}" base=""
    base="${path##*/}"

    [[ -n "${path}" ]] || return 1
    [[ -n "${base}" && "${base}" != "/" ]] || return 1

    if [[ "${base}" == .* && "${base#*.}" != *.* ]]; then
        printf '%s\n' "${base}"
        return 0
    fi

    printf '%s\n' "${base%.*}"

}
file_ext () {

    local path="${1:-}" base=""
    base="${path##*/}"

    [[ -n "${path}" ]] || return 1
    [[ "${base}" == *.* ]] || return 1
    [[ "${base}" != .* ]] || { [[ "${base#*.}" == *.* ]] || return 1; }

    printf '%s\n' "${base##*.}"

}
file_size () {

    local path="${1:-}"
    [[ -f "${path}" ]] || return 1

    wc -c < "${path}" | tr -d '[:space:]'

}
file_lines () {

    local path="${1:-}"
    [[ -f "${path}" ]] || return 1

    wc -l < "${path}" | tr -d '[:space:]'

}

has_line () {

    local file="${1:-}" line="${2-}"

    [[ -f "${file}" && -n "${line}" ]] || return 1
    grep -Fqx -- "${line}" "${file}" 2>/dev/null

}
need_line () {

    local file="${1:-}" line="${2-}"

    has_line "${file}" "${line}" && return 0
    die "Missing line in file: ${file}"

}

line_position () {

    local file="${1:-}" line="${2-}" pos=""

    [[ -f "${file}" && -n "${line}" ]] || return 1

    pos="$(grep -n -F -x -- "${line}" "${file}" 2>/dev/null | head -n 1)" || return 1
    [[ -n "${pos}" ]] || return 1

    printf '%s\n' "${pos%%:*}"

}
add_line () {

    local file="${1:-}" line="${2-}"

    [[ -n "${file}" && -n "${line}" ]] || return 1

    if [[ ! -e "${file}" ]]; then
        printf '%s\n' "${line}" > "${file}" || return 1
        return 0
    fi

    printf '%s\n' "${line}" >> "${file}"

}
ensure_line () {

    local file="${1:-}" line="${2-}"

    [[ -n "${file}" && -n "${line}" ]] || return 1

    has_line "${file}" "${line}" && return 0
    add_line "${file}" "${line}"

}
remove_line () {

    local file="${1:-}" line="${2-}" tmp="" x="" removed=0

    [[ -f "${file}" && -n "${line}" ]] || return 1
    tmp="$(mktemp "${TMPDIR:-/tmp}/remove_line.XXXXXX")" || return 1

    while IFS= read -r x || [[ -n "${x}" ]]; do

        if [[ "${x}" == "${line}" ]]; then
            removed=1
            continue
        fi

        printf '%s\n' "${x}" >> "${tmp}" || { rm -f -- "${tmp}"; return 1; }

    done < "${file}"

    (( removed )) || { rm -f -- "${tmp}"; return 1; }
    command mv -- "${tmp}" "${file}"

}

replace_line () {

    local file="${1:-}" old="${2-}" new="${3-}" tmp="" done=0 x=""

    [[ -f "${file}" && -n "${old}" ]] || return 1
    tmp="$(mktemp "${TMPDIR:-/tmp}/replace_line.XXXXXX")" || return 1

    while IFS= read -r x || [[ -n "${x}" ]]; do

        if (( ! done )) && [[ "${x}" == "${old}" ]]; then
            printf '%s\n' "${new}" >> "${tmp}" || { rm -f -- "${tmp}"; return 1; }
            done=1
            continue
        fi

        printf '%s\n' "${x}" >> "${tmp}" || { rm -f -- "${tmp}"; return 1; }

    done < "${file}"

    (( done )) || { rm -f -- "${tmp}"; return 1; }
    command mv -- "${tmp}" "${file}"

}
replace_all_lines () {

    local file="${1:-}" old="${2-}" new="${3-}" tmp="" x="" done=0

    [[ -f "${file}" && -n "${old}" ]] || return 1
    tmp="$(mktemp "${TMPDIR:-/tmp}/replace_all_lines.XXXXXX")" || return 1

    while IFS= read -r x || [[ -n "${x}" ]]; do

        if [[ "${x}" == "${old}" ]]; then
            printf '%s\n' "${new}" >> "${tmp}" || { rm -f -- "${tmp}"; return 1; }
            done=1
            continue
        fi

        printf '%s\n' "${x}" >> "${tmp}" || { rm -f -- "${tmp}"; return 1; }

    done < "${file}"

    (( done )) || { rm -f -- "${tmp}"; return 1; }
    command mv -- "${tmp}" "${file}"

}

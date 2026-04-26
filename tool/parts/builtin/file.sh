
file::has () {

    command -v "${1:-}" >/dev/null 2>&1

}
file::die () {

    local msg="${1:-}" code="${2:-1}"

    [[ "${code}" =~ ^[0-9]+$ ]] || code=1
    [[ -n "${msg}" ]] && printf '[ERR] %s\n' "${msg}" >&2
    [[ "${-}" == *i* ]] && return "${code}"

    exit "${code}"

}
file::valid () {

    local p="${1-}"

    [[ -n "${p}" ]] || return 1
    [[ "${p}" != *$'\n'* && "${p}" != *$'\r'* ]] || return 1

    return 0

}

file::exists () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" ]]

}
file::missing () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ ! -f "${p}" ]]

}
file::is_link () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -L "${p}" && -f "${p}" ]]

}
file::is_empty () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1
    [[ ! -s "${p}" ]]

}
file::is_filled () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -s "${p}" ]]

}
file::is_readable () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]]

}
file::is_writable () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -w "${p}" ]]

}
file::is_executable () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -x "${p}" ]]

}
file::readable () {

    file::is_readable "$@"

}
file::writable () {

    file::is_writable "$@"

}
file::executable () {

    file::is_executable "$@"

}
file::is_text () {

    local p="${1-}" sample=""

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1
    [[ -s "${p}" ]] || return 0

    if sys::has file; then

        sample="$(file -b --mime-encoding "${p}" 2>/dev/null || true)"

        case "${sample}" in
            binary) return 1 ;;
            "") ;;
            *) return 0 ;;
        esac

    fi

    if LC_ALL=C grep -lI -- '' "${p}" >/dev/null 2>&1; then return 0; fi

    return 1

}
file::is_binary () {

    file::is_text "${1-}" && return 1
    [[ -f "${1-}" ]]

}

file::make () {

    local p="${1-}" mode="${2:-}" parent=""

    file::valid "${p}" || return 1

    if [[ -e "${p}" || -L "${p}" ]]; then
        [[ -f "${p}" ]] || return 1
        [[ -n "${mode}" ]] && chmod -- "${mode}" "${p}" 2>/dev/null
        return 0
    fi

    parent="$(path::dir "${p}" 2>/dev/null || true)"
    [[ -n "${parent}" ]] || return 1

    if [[ ! -d "${parent}" ]]; then
        mkdir -p -- "${parent}" 2>/dev/null || return 1
    fi

    : > "${p}" 2>/dev/null || return 1

    if [[ -n "${mode}" ]]; then
        chmod -- "${mode}" "${p}" 2>/dev/null || return 1
    fi

    return 0

}
file::ensure () {

    file::make "$@"

}
file::touch () {

    local p="${1-}" parent=""

    file::valid "${p}" || return 1

    if [[ -f "${p}" ]]; then
        if sys::has touch; then touch -- "${p}" 2>/dev/null
        else : >> "${p}" 2>/dev/null
        fi
        return
    fi
    if [[ -e "${p}" || -L "${p}" ]]; then
        return 1
    fi

    parent="$(path::dir "${p}" 2>/dev/null || true)"
    [[ -n "${parent}" ]] || return 1

    if [[ ! -d "${parent}" ]]; then
        mkdir -p -- "${parent}" 2>/dev/null || return 1
    fi

    if sys::has touch; then touch -- "${p}" 2>/dev/null
    else : > "${p}" 2>/dev/null
    fi

}
file::make_temp () {

    path::mktemp "$@"

}

file::remove () {

    local p="${1-}"

    file::valid "${p}" || return 1

    [[ -f "${p}" || -L "${p}" ]] || return 0
    rm -f -- "${p}" 2>/dev/null

}
file::truncate () {

    local p="${1-}" size="${2:-0}"

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1
    [[ "${size}" =~ ^[0-9]+$ ]] || return 1

    if (( size == 0 )); then
        : > "${p}" 2>/dev/null
        return
    fi

    if sys::has truncate; then
        truncate -s "${size}" < "${p}" 2>/dev/null && return 0
    fi
    if sys::has dd; then
        dd if=/dev/null of="${p}" bs=1 count=0 seek="${size}" status=none 2>/dev/null
        return
    fi

    return 1

}

file::copy () {

    local from="${1-}" to="${2-}" parent=""

    file::valid "${from}" || return 1
    file::valid "${to}" || return 1

    [[ -f "${from}" || -L "${from}" ]] || return 1
    sys::has cp || return 1

    parent="$(path::dir "${to}" 2>/dev/null || true)"
    [[ -n "${parent}" && -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    cp -f -- "${from}" "${to}" 2>/dev/null

}
file::copy_safe () {

    local from="${1-}" to="${2-}"

    file::valid "${from}" || return 1
    file::valid "${to}" || return 1

    [[ -f "${from}" || -L "${from}" ]] || return 1
    [[ ! -e "${to}" && ! -L "${to}" ]] || return 1

    file::copy "${from}" "${to}"

}
file::move () {

    local from="${1-}" to="${2-}" parent=""

    file::valid "${from}" || return 1
    file::valid "${to}" || return 1

    [[ -f "${from}" || -L "${from}" ]] || return 1
    sys::has mv || return 1

    parent="$(path::dir "${to}" 2>/dev/null || true)"
    [[ -n "${parent}" && -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    mv -f -- "${from}" "${to}" 2>/dev/null

}
file::rename () {

    file::move "$@"

}
file::link () {

    local from="${1-}" to="${2-}"

    file::valid "${from}" || return 1
    file::valid "${to}" || return 1

    [[ -f "${from}" ]] || return 1
    path::link "${from}" "${to}"

}
file::symlink () {

    local from="${1-}" to="${2-}"

    file::valid "${from}" || return 1
    file::valid "${to}" || return 1

    path::symlink "${from}" "${to}"

}

file::read () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1

    cat < "${p}" 2>/dev/null

}
file::read_safe () {

    local p="${1-}" content=""

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1

    IFS= read -r -d '' content < "${p}" 2>/dev/null || true
    printf '%s' "${content}"

}
file::lines () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1

    cat < "${p}" 2>/dev/null

}
file::lines_count () {

    local p="${1-}" n=""

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1

    if sys::has wc; then

        n="$(wc -l < "${p}" 2>/dev/null | tr -d '[:space:]')"
        [[ "${n}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${n}"; return 0; }

    fi

    n=0
    while IFS= read -r _; do n=$(( n + 1 )); done < "${p}"

    printf '%s\n' "${n}"

}
file::head () {

    local p="${1-}" n="${2:-10}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1
    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    if sys::has head; then head -n "${n}" < "${p}" 2>/dev/null
    else awk -v n="${n}" 'NR <= n; NR > n { exit }' < "${p}" 2>/dev/null
    fi

}
file::tail () {

    local p="${1-}" n="${2:-10}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1
    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    if sys::has tail; then tail -n "${n}" < "${p}" 2>/dev/null
    else awk -v n="${n}" '{ buf[NR % n] = $0 } END { for ( i = NR - n + 1; i <= NR; i++ ) if ( i > 0 ) print buf[i % n] }' < "${p}" 2>/dev/null
    fi

}
file::first_line () {

    local p="${1-}" line=""

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1

    IFS= read -r line < "${p}" 2>/dev/null || true
    printf '%s' "${line}"

}
file::last_line () {

    local p="${1-}" line=""

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1

    if sys::has tail; then tail -n 1 < "${p}" 2>/dev/null; return; fi

    while IFS= read -r line || [[ -n "${line}" ]]; do
        :
    done < "${p}"

    printf '%s' "${line}"

}
file::line () {

    local p="${1-}" n="${2:-1}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1
    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    (( n > 0 )) || return 1

    if sys::has sed; then sed -n "${n}p" < "${p}" 2>/dev/null
    else awk -v n="${n}" 'NR == n { print; exit }' < "${p}" 2>/dev/null
    fi

}
file::range () {

    local p="${1-}" from="${2:-1}" to="${3:-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1

    [[ "${from}" =~ ^[0-9]+$ ]] || return 1
    [[ -z "${to}" || "${to}" =~ ^[0-9]+$ ]] || return 1

    (( from > 0 )) || return 1

    if [[ -n "${to}" ]]; then
        (( to >= from )) || return 1
        if sys::has sed; then sed -n "${from},${to}p" < "${p}" 2>/dev/null
        else awk -v a="${from}" -v b="${to}" 'NR >= a && NR <= b; NR > b { exit }' < "${p}" 2>/dev/null
        fi
    else
        if sys::has sed; then sed -n "${from},\$p" < "${p}" 2>/dev/null
        else awk -v a="${from}" 'NR >= a' < "${p}" 2>/dev/null
        fi
    fi

}

file::write () {

    local p="${1-}" content="${2-}" parent=""

    file::valid "${p}" || return 1

    parent="$(path::dir "${p}" 2>/dev/null || true)"
    [[ -n "${parent}" && -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    printf '%s' "${content}" > "${p}" 2>/dev/null

}
file::writeln () {

    local p="${1-}" content="${2-}" parent=""

    file::valid "${p}" || return 1

    parent="$(path::dir "${p}" 2>/dev/null || true)"
    [[ -n "${parent}" && -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    printf '%s\n' "${content}" > "${p}" 2>/dev/null

}
file::write_lines () {

    local p="${1-}" parent=""

    file::valid "${p}" || return 1
    shift || true

    parent="$(path::dir "${p}" 2>/dev/null || true)"
    [[ -n "${parent}" && -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    if (( $# > 0 )); then printf '%s\n' "$@" > "${p}" 2>/dev/null
    else : > "${p}" 2>/dev/null
    fi

}
file::write_atomic () {

    local p="${1-}" content="${2-}" parent="" tmp="" mode="" rc=0

    file::valid "${p}" || return 1

    parent="$(path::dir "${p}" 2>/dev/null || true)"
    [[ -n "${parent}" ]] || return 1

    if [[ ! -d "${parent}" ]]; then
        mkdir -p -- "${parent}" 2>/dev/null || return 1
    fi

    if [[ -f "${p}" ]]; then
        mode="$(path::mode "${p}" 2>/dev/null || true)"
    fi

    if sys::has mktemp; then tmp="$(mktemp -- "${p}.XXXXXXXX" 2>/dev/null || true)"
    else tmp="${p}.tmp.$$.${RANDOM}"
    fi

    [[ -n "${tmp}" ]] || return 1

    printf '%s' "${content}" > "${tmp}" 2>/dev/null
    rc=$?

    if (( rc != 0 )); then
        rm -f -- "${tmp}" 2>/dev/null
        return "${rc}"
    fi

    if [[ -n "${mode}" ]]; then
        chmod -- "${mode}" "${tmp}" 2>/dev/null || true
    fi

    mv -f -- "${tmp}" "${p}" 2>/dev/null
    rc=$?

    if (( rc != 0 )); then
        rm -f -- "${tmp}" 2>/dev/null
    fi

    return "${rc}"

}
file::pipe () {

    local p="${1-}" parent=""

    file::valid "${p}" || return 1

    parent="$(path::dir "${p}" 2>/dev/null || true)"
    [[ -n "${parent}" && -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    cat > "${p}" 2>/dev/null

}

file::append () {

    local p="${1-}" content="${2-}" parent=""

    file::valid "${p}" || return 1

    parent="$(path::dir "${p}" 2>/dev/null || true)"
    [[ -n "${parent}" && -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    printf '%s' "${content}" >> "${p}" 2>/dev/null

}
file::appendln () {

    local p="${1-}" content="${2-}" parent=""

    file::valid "${p}" || return 1

    parent="$(path::dir "${p}" 2>/dev/null || true)"
    [[ -n "${parent}" && -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    printf '%s\n' "${content}" >> "${p}" 2>/dev/null

}
file::append_lines () {

    local p="${1-}" parent=""

    file::valid "${p}" || return 1
    shift || true

    parent="$(path::dir "${p}" 2>/dev/null || true)"
    [[ -n "${parent}" && -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    (( $# > 0 )) || return 0
    printf '%s\n' "$@" >> "${p}" 2>/dev/null

}
file::append_unique () {

    local p="${1-}" line="${2-}" parent=""

    file::valid "${p}" || return 1
    [[ -n "${line}" ]] || return 1

    parent="$(path::dir "${p}" 2>/dev/null || true)"
    [[ -n "${parent}" && -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    if [[ -f "${p}" ]] && grep -Fxq -- "${line}" "${p}" 2>/dev/null; then
        return 0
    fi

    printf '%s\n' "${line}" >> "${p}" 2>/dev/null

}
file::prepend () {

    local p="${1-}" content="${2-}" tmp=""

    file::valid "${p}" || return 1

    if [[ ! -f "${p}" ]]; then file::write "${p}" "${content}"; return; fi

    if sys::has mktemp; then tmp="$(mktemp -- "${p}.XXXXXXXX" 2>/dev/null || true)"
    else tmp="${p}.tmp.$$.${RANDOM}"
    fi

    [[ -n "${tmp}" ]] || return 1

    {
        printf '%s' "${content}"
        cat -- "${p}"
    } > "${tmp}" 2>/dev/null || { rm -f -- "${tmp}" 2>/dev/null; return 1; }

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::prependln () {

    local p="${1-}" content="${2-}" tmp=""

    file::valid "${p}" || return 1

    if [[ ! -f "${p}" ]]; then file::writeln "${p}" "${content}"; return; fi

    if sys::has mktemp; then tmp="$(mktemp -- "${p}.XXXXXXXX" 2>/dev/null || true)"
    else tmp="${p}.tmp.$$.${RANDOM}"
    fi

    [[ -n "${tmp}" ]] || return 1

    {
        printf '%s\n' "${content}"
        cat -- "${p}"
    } > "${tmp}" 2>/dev/null || { rm -f -- "${tmp}" 2>/dev/null; return 1; }

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::prepend_lines () {

    local p="${1-}" tmp=""

    file::valid "${p}" || return 1
    shift || true

    if [[ ! -f "${p}" ]]; then file::write_lines "${p}" "$@"; return; fi

    if sys::has mktemp; then tmp="$(mktemp -- "${p}.XXXXXXXX" 2>/dev/null || true)"
    else tmp="${p}.tmp.$$.${RANDOM}"
    fi

    [[ -n "${tmp}" ]] || return 1

    {
        (( $# > 0 )) && printf '%s\n' "$@"
        cat -- "${p}"
    } > "${tmp}" 2>/dev/null || { rm -f -- "${tmp}" 2>/dev/null; return 1; }

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}

file::contains () {

    local p="${1-}" needle="${2-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1
    [[ -n "${needle}" ]] || return 1

    grep -Fq -- "${needle}" "${p}" 2>/dev/null

}
file::contains_line () {

    local p="${1-}" line="${2-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1
    [[ -n "${line}" ]] || return 1

    grep -Fxq -- "${line}" "${p}" 2>/dev/null

}
file::matches () {

    local p="${1-}" regex="${2-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1
    [[ -n "${regex}" ]] || return 1

    grep -Eq -- "${regex}" "${p}" 2>/dev/null

}
file::starts_with () {

    local p="${1-}" needle="${2-}" first=""

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1
    [[ -n "${needle}" ]] || return 1

    first="$(file::first_line "${p}" 2>/dev/null || true)"
    [[ "${first}" == "${needle}"* ]]

}
file::ends_with () {

    local p="${1-}" needle="${2-}" last=""

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1
    [[ -n "${needle}" ]] || return 1

    last="$(file::last_line "${p}" 2>/dev/null || true)"
    [[ "${last}" == *"${needle}" ]]

}
file::grep () {

    local p="${1-}" pattern="${2-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1
    [[ -n "${pattern}" ]] || return 1

    grep -E -- "${pattern}" "${p}" 2>/dev/null

}
file::find_line () {

    local p="${1-}" pattern="${2-}" v=""

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1
    [[ -n "${pattern}" ]] || return 1

    v="$(grep -nE -- "${pattern}" "${p}" 2>/dev/null | head -n 1 | cut -d: -f1)"
    [[ "${v}" =~ ^[0-9]+$ ]] || return 1

    printf '%s\n' "${v}"

}
file::count_matches () {

    local p="${1-}" pattern="${2-}" v=""

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1
    [[ -n "${pattern}" ]] || return 1

    v="$(grep -cE -- "${pattern}" "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] || v=0

    printf '%s\n' "${v}"

}

file::replace () {

    local p="${1-}" from="${2-}" to="${3-}" tmp="" rc=0

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1
    [[ -n "${from}" ]] || return 1
    sys::has sed || return 1

    if sys::has mktemp; then tmp="$(mktemp -- "${p}.XXXXXXXX" 2>/dev/null || true)"
    else tmp="${p}.tmp.$$.${RANDOM}"
    fi

    [[ -n "${tmp}" ]] || return 1

    local esc_from="" esc_to=""
    esc_from="$(printf '%s' "${from}" | sed -e 's/[]\/$*.^[]/\\&/g')"
    esc_to="$(printf '%s' "${to}" | sed -e 's/[\/&]/\\&/g')"

    sed "s/${esc_from}/${esc_to}/g" < "${p}" > "${tmp}" 2>/dev/null
    rc=$?

    if (( rc != 0 )); then
        rm -f -- "${tmp}" 2>/dev/null
        return "${rc}"
    fi

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::replace_line () {

    local p="${1-}" n="${2-}" content="${3-}" tmp="" rc=0

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1
    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    (( n > 0 )) || return 1
    sys::has awk || return 1

    if sys::has mktemp; then tmp="$(mktemp -- "${p}.XXXXXXXX" 2>/dev/null || true)"
    else tmp="${p}.tmp.$$.${RANDOM}"
    fi

    [[ -n "${tmp}" ]] || return 1

    awk -v n="${n}" -v c="${content}" 'NR == n { print c; next } { print }' < "${p}" > "${tmp}" 2>/dev/null
    rc=$?

    if (( rc != 0 )); then
        rm -f -- "${tmp}" 2>/dev/null
        return "${rc}"
    fi

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::insert_line () {

    local p="${1-}" n="${2-}" content="${3-}" tmp="" rc=0

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1
    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    (( n > 0 )) || return 1
    sys::has awk || return 1

    if sys::has mktemp; then tmp="$(mktemp -- "${p}.XXXXXXXX" 2>/dev/null || true)"
    else tmp="${p}.tmp.$$.${RANDOM}"
    fi

    [[ -n "${tmp}" ]] || return 1

    awk -v n="${n}" -v c="${content}" 'NR == n { print c } { print }' < "${p}" > "${tmp}" 2>/dev/null
    rc=$?

    if (( rc != 0 )); then
        rm -f -- "${tmp}" 2>/dev/null
        return "${rc}"
    fi

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::delete_line () {

    local p="${1-}" n="${2-}" tmp="" rc=0

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1
    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    (( n > 0 )) || return 1
    sys::has awk || return 1

    if sys::has mktemp; then tmp="$(mktemp -- "${p}.XXXXXXXX" 2>/dev/null || true)"
    else tmp="${p}.tmp.$$.${RANDOM}"
    fi

    [[ -n "${tmp}" ]] || return 1

    awk -v n="${n}" 'NR != n { print }' < "${p}" > "${tmp}" 2>/dev/null
    rc=$?

    if (( rc != 0 )); then
        rm -f -- "${tmp}" 2>/dev/null
        return "${rc}"
    fi

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::delete_match () {

    local p="${1-}" pattern="${2-}" tmp="" rc=0

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1
    [[ -n "${pattern}" ]] || return 1

    sys::has grep || return 1

    if sys::has mktemp; then tmp="$(mktemp -- "${p}.XXXXXXXX" 2>/dev/null || true)"
    else tmp="${p}.tmp.$$.${RANDOM}"
    fi

    [[ -n "${tmp}" ]] || return 1

    grep -Ev -- "${pattern}" "${p}" > "${tmp}" 2>/dev/null
    rc=$?

    if (( rc != 0 && rc != 1 )); then
        rm -f -- "${tmp}" 2>/dev/null
        return 1
    fi

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::dedupe () {

    local p="${1-}" tmp="" rc=0

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1
    sys::has awk || return 1

    if sys::has mktemp; then tmp="$(mktemp -- "${p}.XXXXXXXX" 2>/dev/null || true)"
    else tmp="${p}.tmp.$$.${RANDOM}"
    fi

    [[ -n "${tmp}" ]] || return 1

    awk '!seen[$0]++' < "${p}" > "${tmp}" 2>/dev/null
    rc=$?

    if (( rc != 0 )); then
        rm -f -- "${tmp}" 2>/dev/null
        return "${rc}"
    fi

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::sort () {

    local p="${1-}" order="${2:-asc}" tmp="" rc=0

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1
    sys::has sort || return 1

    if sys::has mktemp; then tmp="$(mktemp -- "${p}.XXXXXXXX" 2>/dev/null || true)"
    else tmp="${p}.tmp.$$.${RANDOM}"
    fi

    [[ -n "${tmp}" ]] || return 1

    case "${order}" in
        asc|"") LC_ALL=C sort < "${p}" > "${tmp}" 2>/dev/null ;;
        desc|reverse) LC_ALL=C sort -r < "${p}" > "${tmp}" 2>/dev/null ;;
        *) rm -f -- "${tmp}" 2>/dev/null; return 1 ;;
    esac

    rc=$?

    if (( rc != 0 )); then
        rm -f -- "${tmp}" 2>/dev/null
        return "${rc}"
    fi

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}

file::size () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1

    path::size "${p}"

}
file::mtime () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1

    path::mtime "${p}"

}
file::age () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1

    path::age "${p}"

}
file::owner () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1

    path::owner "${p}"

}
file::group () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1

    path::group "${p}"

}
file::mode () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1

    path::mode "${p}"

}
file::ext () {

    path::ext "$@"

}
file::stem () {

    path::stem "$@"

}
file::name () {

    path::base "$@"

}
file::basename () {

    path::base "$@"

}
file::dir () {

    path::dir "$@"

}
file::dirname () {

    path::dir "$@"

}

file::abs () {

    local p="${1-}"

    file::valid "${p}" || return 1
    path::abs "${p}"

}
file::resolve () {

    local p="${1-}"

    file::valid "${p}" || return 1
    [[ -e "${p}" || -L "${p}" ]] || return 1

    path::resolve "${p}"

}
file::rel () {

    local target="${1-}" base="${2:-}"

    file::valid "${target}" || return 1
    path::rel "${target}" "${base}"

}

file::same () {

    local a="${1-}" b="${2-}"

    file::valid "${a}" || return 1
    file::valid "${b}" || return 1

    [[ -f "${a}" && -f "${b}" ]] || return 1

    path::same "${a}" "${b}"

}
file::equal () {

    local a="${1-}" b="${2-}"

    file::valid "${a}" || return 1
    file::valid "${b}" || return 1

    [[ -f "${a}" && -r "${a}" ]] || return 1
    [[ -f "${b}" && -r "${b}" ]] || return 1

    if sys::has cmp; then cmp -s -- "${a}" "${b}"
    elif sys::has diff; then diff -q -- "${a}" "${b}" >/dev/null 2>&1
    else
        local sa="" sb=""
        sa="$(file::hash "${a}" 2>/dev/null || true)"
        sb="$(file::hash "${b}" 2>/dev/null || true)"
        [[ -n "${sa}" && -n "${sb}" && "${sa}" == "${sb}" ]]
    fi

}
file::diff () {

    local a="${1-}" b="${2-}"

    file::valid "${a}" || return 1
    file::valid "${b}" || return 1

    [[ -f "${a}" && -r "${a}" ]] || return 1
    [[ -f "${b}" && -r "${b}" ]] || return 1

    sys::has diff || return 1
    diff -u -- "${a}" "${b}" 2>/dev/null

}

file::hash () {

    local p="${1-}" algo="${2:-sha256}" v="" cmd=""

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1

    case "${algo}" in
        md5)    cmd="md5sum" ;;
        sha1)   cmd="sha1sum" ;;
        sha224) cmd="sha224sum" ;;
        sha256) cmd="sha256sum" ;;
        sha384) cmd="sha384sum" ;;
        sha512) cmd="sha512sum" ;;
        *)      return 1 ;;
    esac

    if sys::has "${cmd}"; then

        v="$("${cmd}" < "${p}" 2>/dev/null | awk '{print $1}' | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has openssl; then

        case "${algo}" in
            md5|sha1|sha224|sha256|sha384|sha512)
                v="$(openssl dgst "-${algo}" < "${p}" 2>/dev/null | awk '{print $NF}' | head -n 1)"
                [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
            ;;
        esac

    fi
    if sys::has shasum; then

        case "${algo}" in
            sha1)   v="$(shasum -a 1   < "${p}" 2>/dev/null | awk '{print $1}')" ;;
            sha224) v="$(shasum -a 224 < "${p}" 2>/dev/null | awk '{print $1}')" ;;
            sha256) v="$(shasum -a 256 < "${p}" 2>/dev/null | awk '{print $1}')" ;;
            sha384) v="$(shasum -a 384 < "${p}" 2>/dev/null | awk '{print $1}')" ;;
            sha512) v="$(shasum -a 512 < "${p}" 2>/dev/null | awk '{print $1}')" ;;
        esac

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
file::md5 () {

    file::hash "${1-}" md5

}
file::sha1 () {

    file::hash "${1-}" sha1

}
file::sha256 () {

    file::hash "${1-}" sha256

}
file::sha512 () {

    file::hash "${1-}" sha512

}

file::backup () {

    local p="${1-}" suffix="${2:-.bak}" target=""

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1

    target="${p}${suffix}"
    cp -f -- "${p}" "${target}" 2>/dev/null && printf '%s' "${target}"

}
file::restore () {

    local p="${1-}" suffix="${2:-.bak}" source=""

    file::valid "${p}" || return 1

    source="${p}${suffix}"
    [[ -f "${source}" ]] || return 1

    mv -f -- "${source}" "${p}" 2>/dev/null

}
file::rotate () {

    local p="${1-}" max="${2:-5}" i=0 src="" dst=""

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 0
    [[ "${max}" =~ ^[0-9]+$ ]] || return 1

    (( max > 0 )) || return 1

    for (( i=max-1; i>=1; i-- )); do

        src="${p}.${i}"
        dst="${p}.$(( i + 1 ))"

        [[ -f "${src}" ]] && mv -f -- "${src}" "${dst}" 2>/dev/null

    done

    mv -f -- "${p}" "${p}.1" 2>/dev/null

}

file::lock () {

    local p="${1-}" max="${2:-30}" i=0 lock=""

    file::valid "${p}" || return 1
    [[ "${max}" =~ ^[0-9]+$ ]] || max=30

    lock="${p}.lock"

    if sys::has flock; then

        exec {__file_lock_fd__}>"${lock}" 2>/dev/null || return 1
        flock -n "${__file_lock_fd__}" 2>/dev/null && return 0

        for (( i=0; i<max; i++ )); do
            sleep 1 2>/dev/null || true
            flock -n "${__file_lock_fd__}" 2>/dev/null && return 0
        done

        exec {__file_lock_fd__}>&- 2>/dev/null || true
        return 1

    fi

    for (( i=0; i<max; i++ )); do

        if ( set -C; : > "${lock}" ) 2>/dev/null; then
            printf '%s' "$$" > "${lock}" 2>/dev/null
            return 0
        fi

        sleep 1 2>/dev/null || true

    done

    return 1

}
file::unlock () {

    local p="${1-}" lock=""

    file::valid "${p}" || return 1

    lock="${p}.lock"

    if [[ -n "${__file_lock_fd__:-}" ]]; then
        exec {__file_lock_fd__}>&- 2>/dev/null || true
        unset __file_lock_fd__
    fi

    rm -f -- "${lock}" 2>/dev/null

}

file::mime () {

    local p="${1-}" v=""

    file::valid "${p}" || return 1
    [[ -f "${p}" ]] || return 1

    if sys::has file; then

        v="$(file -b --mime-type < "${p}" 2>/dev/null | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
file::type () {

    local p="${1-}" ext=""

    file::valid "${p}" || return 1

    ext="$(path::ext "${p}" 2>/dev/null || true)"
    ext="${ext,,}"

    case "${ext}" in
        sh|bash|zsh|fish)                printf 'script';       return 0 ;;
        py|pyw)                          printf 'python';       return 0 ;;
        js|mjs|cjs|jsx|ts|tsx)           printf 'javascript';   return 0 ;;
        rs)                              printf 'rust';         return 0 ;;
        go)                              printf 'go';           return 0 ;;
        c|h)                             printf 'c';            return 0 ;;
        cpp|cxx|cc|hpp|hxx|hh)           printf 'cpp';          return 0 ;;
        java|kt|scala)                   printf 'jvm';          return 0 ;;
        rb)                              printf 'ruby';         return 0 ;;
        php)                             printf 'php';          return 0 ;;
        lua)                             printf 'lua';          return 0 ;;
        r)                               printf 'r';            return 0 ;;
        json|yaml|yml|toml|ini|conf|cfg) printf 'config';       return 0 ;;
        xml|html|htm|svg)                printf 'markup';       return 0 ;;
        css|scss|sass|less)              printf 'style';        return 0 ;;
        md|rst|adoc|txt|log)             printf 'text';         return 0 ;;
        png|jpg|jpeg|gif|webp|bmp|ico|tiff) printf 'image';     return 0 ;;
        mp3|wav|flac|ogg|m4a|aac)        printf 'audio';        return 0 ;;
        mp4|mkv|avi|mov|webm|wmv)        printf 'video';        return 0 ;;
        zip|tar|gz|bz2|xz|zst|7z|rar)    printf 'archive';      return 0 ;;
        pdf)                             printf 'pdf';          return 0 ;;
        doc|docx|odt|rtf)                printf 'document';     return 0 ;;
        xls|xlsx|ods|csv|tsv)            printf 'spreadsheet';  return 0 ;;
        ppt|pptx|odp)                    printf 'presentation'; return 0 ;;
        sql|db|sqlite|sqlite3)           printf 'database';     return 0 ;;
        exe|dll|so|dylib|a|lib|o|obj)    printf 'binary';       return 0 ;;
    esac

    [[ -f "${p}" ]] || { printf 'unknown'; return 0; }

    if file::is_binary "${p}"; then printf 'binary'
    else printf 'text'
    fi

}

file::tail_follow () {

    local p="${1-}" n="${2:-10}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1
    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    sys::has tail || return 1
    tail -n "${n}" -F < "${p}" 2>/dev/null

}
file::watch () {

    local p="${1-}" interval="${2:-1}" prev="" cur=""

    file::valid "${p}" || return 1
    [[ "${interval}" =~ ^[0-9]+([.][0-9]+)?$ ]] || interval=1

    while :; do

        if [[ -f "${p}" ]]; then cur="$(file::mtime "${p}" 2>/dev/null || printf '0')"
        else cur="0"
        fi

        if [[ "${cur}" != "${prev}" ]]; then
            [[ -n "${prev}" ]] && return 0
            prev="${cur}"
        fi

        sleep "${interval}" 2>/dev/null || return 1

    done

}

file::download () {

    local url="${1-}" out="${2-}" parent=""

    [[ -n "${url}" ]] || return 1
    file::valid "${out}" || return 1

    parent="$(path::dir "${out}" 2>/dev/null || true)"
    [[ -n "${parent}" && -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    if sys::has curl; then curl -fsSL --retry 3 -o "${out}" -- "${url}" 2>/dev/null
    elif sys::has wget; then wget -q -O "${out}" -- "${url}" 2>/dev/null
    else return 1
    fi

}

file::head_bytes () {

    local p="${1-}" n="${2:-1024}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1
    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    if sys::has head; then head -c "${n}" < "${p}" 2>/dev/null
    elif sys::has dd; then dd if="${p}" bs=1 count="${n}" 2>/dev/null
    else return 1
    fi

}
file::tail_bytes () {

    local p="${1-}" n="${2:-1024}"

    file::valid "${p}" || return 1
    [[ -f "${p}" && -r "${p}" ]] || return 1
    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    if sys::has tail; then tail -c "${n}" < "${p}" 2>/dev/null
    else return 1
    fi

}

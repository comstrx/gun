
__file_marker__ () {

    return 0

}
__trace_trim__ () {

    local s="${1-}"

    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"

    printf '%s\n' "${s}"

}
__trace_norm__ () {

    local s="${1-}"

    s="${s%$'\r'}"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"

    [[ "${s}" == \#* ]] && {
        printf '\n'
        return 0
    }

    s="${s%%#*}"
    s="${s%"${s##*[![:space:]]}"}"

    while [[ "${s}" == *"  "* ]]; do
        s="${s//  / }"
    done

    printf '%s\n' "${s}"

}
__trace_suffix__ () {

    local s=""
    s="$(__trace_norm__ "${1-}")"

    [[ -n "${s}" ]] || {
        printf '\n'
        return 0
    }

    printf '%s\n' "${s##* }"

}
__trace_find_marker__ () {

    local file="${1:-}" line="${2:-0}" row="" n=0 src="" src_start=0

    [[ -f "${file}" ]] || return 1
    [[ "${line}" =~ ^[0-9]+$ ]] || return 1

    while IFS= read -r row || [[ -n "${row}" ]]; do

        n=$(( n + 1 ))
        (( n > line )) && break

        [[ "${row}" == __file_marker__* ]] || continue

        src="${row#__file_marker__ }"
        src_start="${n}"

    done < "${file}"

    [[ -n "${src}" ]] || return 1

    printf '%s\t%s\n' "${src}" "${src_start}"

}
__trace_find_best_line__ () {

    local src_file="${1:-}" final_file="${2:-}" final_line="${3:-0}" marker_line="${4:-0}"
    local fallback=1 best=""

    [[ -f "${src_file}"  ]] || return 1
    [[ -f "${final_file}" ]] || return 1
    [[ "${final_line}"  =~ ^[0-9]+$ ]] || return 1
    [[ "${marker_line}" =~ ^[0-9]+$ ]] || return 1

    fallback=$(( final_line - marker_line ))
    (( fallback >= 1 )) || fallback=1

    best="$(
        awk -v src_file="${src_file}" -v final_file="${final_file}" -v final_line="${final_line}" -v fallback="${fallback}" '
            function trim ( s ) {
                sub(/^[[:space:]]+/, "", s)
                sub(/[[:space:]]+$/, "", s)
                return s
            }
            function norm ( s ) {
                gsub(/\r/, "", s)
                s = trim(s)

                if (s ~ /^#/) return ""

                sub(/[[:space:]]*#[^"'\'']*$/, "", s)
                s = trim(s)

                gsub(/[[:space:]]+/, " ", s)
                return s
            }
            function suffix ( s, a, n ) {
                s = norm(s)
                if (s == "") return ""
                n = split(s, a, /[[:space:]]+/)
                return a[n]
            }
            function abs ( x ) {
                return x < 0 ? -x : x
            }
            BEGIN {

                for (k = -2; k <= 2; k++) {
                    idx = final_line + k
                    raw = ""

                    if (idx >= 1) {
                        cmd = "sed -n \047" idx "p\047 \"" final_file "\""
                        cmd | getline raw
                        close(cmd)
                    }

                    if (raw ~ /^__file_marker__[[:space:]]+/) raw = ""

                    ctx_raw[k]  = raw
                    ctx_norm[k] = norm(raw)
                    ctx_suf[k]  = suffix(raw)
                }

                src_count = 0
                for (i = 1; (getline raw < src_file) > 0; i++) {
                    src_raw[i]  = raw
                    src_norm[i] = norm(raw)
                    src_suf[i]  = suffix(raw)
                    src_count = i
                }
                close(src_file)

                best_score = -1
                best_line  = fallback
                best_dist  = 10 ^ 9

                for (i = 1; i <= src_count; i++) {

                    score = 0
                    dist  = abs(i - fallback)

                    if (ctx_suf[0] != "" && src_suf[i] == ctx_suf[0]) score += 40
                    if (ctx_norm[0] != "" && src_norm[i] == ctx_norm[0]) score += 80

                    if (ctx_suf[-1] != "" && i > 1           && src_suf[i-1] == ctx_suf[-1]) score += 14
                    if (ctx_suf[1]  != "" && i < src_count   && src_suf[i+1] == ctx_suf[1])  score += 14
                    if (ctx_suf[-2] != "" && i > 2           && src_suf[i-2] == ctx_suf[-2]) score += 7
                    if (ctx_suf[2]  != "" && i + 2 <= src_count && src_suf[i+2] == ctx_suf[2]) score += 7

                    if (ctx_norm[-1] != "" && i > 1           && src_norm[i-1] == ctx_norm[-1]) score += 22
                    if (ctx_norm[1]  != "" && i < src_count   && src_norm[i+1] == ctx_norm[1])  score += 22
                    if (ctx_norm[-2] != "" && i > 2           && src_norm[i-2] == ctx_norm[-2]) score += 10
                    if (ctx_norm[2]  != "" && i + 2 <= src_count && src_norm[i+2] == ctx_norm[2]) score += 10

                    if (src_norm[i] == "" && ctx_norm[0] != "") score = -1

                    if (score > best_score || (score == best_score && dist < best_dist)) {
                        best_score = score
                        best_line  = i
                        best_dist  = dist
                    }
                }

                if (best_score <= 0) best_line = fallback
                if (best_line < 1) best_line = 1

                print best_line
            }
        '
    )" || true

    [[ "${best}" =~ ^[0-9]+$ ]] || best="${fallback}"
    (( best >= 1 )) || best=1

    printf '%s\n' "${best}"

}
__trace_map_text__ () {

    local text="${1:-}" file="" line="" msg=""
    local src="" marker_line=0 src_line=0

    [[ -n "${text}" ]] || return 1

    file="$(sed -n 's/^\(.*\): line [0-9][0-9]*: .*/\1/p' <<< "${text}" | head -n 1)"
    line="$(sed -n 's/^.*: line \([0-9][0-9]*\): .*/\1/p' <<< "${text}" | head -n 1)"
    msg="$(sed -n 's/^.*: line [0-9][0-9]*: \(.*\)$/\1/p' <<< "${text}" | head -n 1)"

    [[ -f "${file}" ]] || return 1
    [[ "${line}" =~ ^[0-9]+$ ]] || return 1

    IFS=$'\t' read -r src marker_line < <(__trace_find_marker__ "${file}" "${line}") || return 1
    [[ -f "${src}" ]] || return 1

    src_line="$(__trace_find_best_line__ "${src}" "${file}" "${line}" "${marker_line}")" || return 1

    printf '%s:%s: %s\n' "${src}" "${src_line}" "${msg}" >&3

}
__trace_map_line__ () {

    local file="${1:-}" line="${2:-0}" msg="${3:-}"
    local src="" marker_line=0 src_line=0

    [[ -f "${file}" ]] || {
        printf '%s: line %s: %s\n' "${file}" "${line}" "${msg}" >&3
        return 1
    }

    [[ "${line}" =~ ^[0-9]+$ ]] || {
        printf '%s: line %s: %s\n' "${file}" "${line}" "${msg}" >&3
        return 1
    }

    IFS=$'\t' read -r src marker_line < <(__trace_find_marker__ "${file}" "${line}") || {
        printf '%s: line %s: %s\n' "${file}" "${line}" "${msg}" >&3
        return 1
    }

    [[ -f "${src}" ]] || {
        printf '%s: line %s: %s\n' "${file}" "${line}" "${msg}" >&3
        return 1
    }

    src_line="$(__trace_find_best_line__ "${src}" "${file}" "${line}" "${marker_line}")" || src_line=0
    [[ "${src_line}" =~ ^[0-9]+$ ]] || src_line=$(( line - marker_line ))
    (( src_line >= 1 )) || src_line=1

    printf '%s:%s: %s\n' "${src}" "${src_line}" "${msg}" >&3

}
__trace_stderr__ () {

    local line="" pat=""

    pat="^${___TRACE_FILE___}: line [0-9][0-9]*: "

    while IFS= read -r line || [[ -n "${line}" ]]; do

        [[ "${line}" == "__TRACE_EOF__" ]] && break

        if [[ "${line}" =~ ${pat} ]]; then
            __trace_map_text__ "${line}" || printf '%s\n' "${line}" >&3
            continue
        fi

        printf '%s\n' "${line}" >&3

    done

}
__trace_on_err__ () {

    local rc="${1:-1}" line="${2:-0}" cmd="${3:-}"

    case "${rc}" in
        126|127) return 0 ;;
    esac

    __trace_map_line__ "${___TRACE_FILE___}" "${line}" "${cmd}: exit ${rc}" || true

}
__trace_cleanup__ () {

    local rc="${1:-0}"

    trap - ERR EXIT

    printf '%s\n' '__TRACE_EOF__' >&2 || true

    exec 2>&3 || true
    exec 9>&- || true
    exec 8>&- || true
    exec 3>&- || true

    [[ -n "${___TRACE_PID___:-}"  ]] && wait "${___TRACE_PID___}" 2>/dev/null || true
    [[ -n "${___TRACE_FIFO___:-}" ]] && rm -f "${___TRACE_FIFO___}" 2>/dev/null || true

    exit "${rc}"

}
__trace__ () {

    readonly ___TRACE_FILE___="${BASH_SOURCE[0]}"
    readonly ___TRACE_FIFO___="$(mktemp -u "${TMPDIR:-/tmp}/gun-trace.XXXXXX")"

    mkfifo "${___TRACE_FIFO___}" || exit 1

    exec 3>&2
    exec 8<> "${___TRACE_FIFO___}"
    exec 9>  "${___TRACE_FIFO___}"

    __trace_stderr__ <&8 &
    readonly ___TRACE_PID___=$!

    exec 2>&9

    trap 'rc=$?; __trace_on_err__ "${rc}" "${LINENO}" "${BASH_COMMAND}"; __trace_cleanup__ "${rc}"' ERR
    trap 'rc=$?; __trace_cleanup__ "${rc}"' EXIT

}

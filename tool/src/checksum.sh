
new_checksum () {

    local -a targets=( "${SOURCE_DIR}" )

    if ! find "${targets[@]}" -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum | awk '{print $1}'; then
        printf '[ERR]: failed to calculate sha256sum\n' >&2
        return 1
    fi

}
read_checksum () {

    local file="${1:-}"

    [[ -f "${file}" ]] || return 1
    sed -n "s/^readonly ___APP_SRC_CHECKSUM___='\(.*\)'$/\1/p" "${file}" | head -n 1 || return 1

}
check_checksum () {

    local file="${1:-}" old="" new=""

    old="$(read_checksum "${file}")" || return 1
    new="$(new_checksum)" || return 1

    [[ "${old}" == "${new}" ]]

}
build_checksum () {

    local sum=""
    sum="$(new_checksum)" || return 1
    printf "readonly ___APP_SRC_CHECKSUM___='%s'\n" "${sum}"

}

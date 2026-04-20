
home_dir () {

    if [[ -n "${HOME:-}" ]]; then
        printf '%s\n' "${HOME}"
        return 0
    fi
    if is_windows && [[ -n "${USERPROFILE:-}" ]]; then
        printf '%s\n' "${USERPROFILE}"
        return 0
    fi

    return 1

}
ssh_dir () {

    local home=""
    home="$(home_dir)" || return 1

    printf '%s\n' "${home}/.ssh"

}
bin_dir () {

    local home=""
    home="$(home_dir)" || return 1

    if is_windows; then
        printf '%s\n' "${home}/bin"
        return 0
    fi
    if [[ -n "${XDG_BIN_HOME:-}" ]]; then
        printf '%s\n' "${XDG_BIN_HOME%/}"
        return 0
    fi

    printf '%s\n' "${home}/.local/bin"

}
tmp_dir () {

    if [[ -n "${TMPDIR:-}" ]]; then

        printf '%s\n' "${TMPDIR%/}"
        return 0

    fi
    if is_windows; then

        if [[ -n "${TMP:-}" ]]; then
            printf '%s\n' "${TMP%/}"
            return 0
        fi
        if [[ -n "${TEMP:-}" ]]; then
            printf '%s\n' "${TEMP%/}"
            return 0
        fi

    fi

    printf '%s\n' "/tmp"

}
config_dir () {

    local home=""
    home="$(home_dir)" || return 1

    if is_macos; then

        printf '%s\n' "${home}/Library/Application Support"
        return 0

    fi
    if is_windows; then

        if [[ -n "${APPDATA:-}" ]]; then
            printf '%s\n' "${APPDATA%/}"
            return 0
        fi

        printf '%s\n' "${home}/AppData/Roaming"
        return 0

    fi
    if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then

        printf '%s\n' "${XDG_CONFIG_HOME%/}"
        return 0

    fi

    printf '%s\n' "${home}/.config"

}
cache_dir () {

    local home=""
    home="$(home_dir)" || return 1

    if is_macos; then

        printf '%s\n' "${home}/Library/Caches"
        return 0

    fi
    if is_windows; then

        if [[ -n "${LOCALAPPDATA:-}" ]]; then
            printf '%s\n' "${LOCALAPPDATA%/}"
            return 0
        fi

        printf '%s\n' "${home}/AppData/Local"
        return 0

    fi
    if [[ -n "${XDG_CACHE_HOME:-}" ]]; then

        printf '%s\n' "${XDG_CACHE_HOME%/}"
        return 0

    fi

    printf '%s\n' "${home}/.cache"

}
data_dir () {

    local home=""
    home="$(home_dir)" || return 1

    if is_macos; then

        printf '%s\n' "${home}/Library/Application Support"
        return 0

    fi
    if is_windows; then

        if [[ -n "${LOCALAPPDATA:-}" ]]; then

            printf '%s\n' "${LOCALAPPDATA%/}"
            return 0

        fi

        printf '%s\n' "${home}/AppData/Local"
        return 0

    fi
    if [[ -n "${XDG_DATA_HOME:-}" ]]; then

        printf '%s\n' "${XDG_DATA_HOME%/}"
        return 0

    fi

    printf '%s\n' "${home}/.local/share"

}
state_dir () {

    local home=""
    home="$(home_dir)" || return 1

    if is_macos; then

        printf '%s\n' "${home}/Library/Application Support"
        return 0

    fi
    if is_windows; then

        if [[ -n "${LOCALAPPDATA:-}" ]]; then
            printf '%s\n' "${LOCALAPPDATA%/}"
            return 0
        fi

        printf '%s\n' "${home}/AppData/Local"
        return 0

    fi
    if [[ -n "${XDG_STATE_HOME:-}" ]]; then

        printf '%s\n' "${XDG_STATE_HOME%/}"
        return 0

    fi

    printf '%s\n' "${home}/.local/state"

}
runtime_dir () {

    if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
        printf '%s\n' "${XDG_RUNTIME_DIR%/}"
        return 0
    fi
    if is_windows; then
        tmp_dir
        return 0
    fi

    printf '%s\n' "/tmp"

}
desktop_dir () {

    local home=""
    home="$(home_dir)" || return 1

    printf '%s\n' "${home}/Desktop"

}
download_dir () {

    local home=""
    home="$(home_dir)" || return 1

    printf '%s\n' "${home}/Downloads"

}
documents_dir () {

    local home=""
    home="$(home_dir)" || return 1

    printf '%s\n' "${home}/Documents"

}

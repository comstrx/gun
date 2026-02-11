#!/usr/bin/env bash

# Self

WORKSPACE_DIR="${WORKSPACE_DIR:-/var/www}"
PROJECTS_DIR="${PROJECTS_DIR:-/var/www/projects}"

SYNC_DIR="${SYNC_DIR:-/mnt/d}"
ARCHIVE_DIR="${ARCHIVE_DIR:-/mnt/d/Archive}"

OUT_DIR="${OUT_DIR:-out}"

GIT_HTTP_USER="${GIT_HTTP_USER:-x-access-token}"
GIT_HOST="${GIT_HOST:-github.com}"
GIT_AUTH="${GIT_AUTH:-ssh}"
GIT_TOKEN="${GIT_TOKEN:-}"
GIT_SSH_KEY="${GIT_SSH_KEY:-}"

GH_HOST="${GH_HOST:-}"
GH_PROFILE="${GH_PROFILE:-}"

cmd_new () {

    cmd_new_project "$@"

}
cmd_done () {

    source <(parse "$@" -- tag release:bool sync:bool=true backup:bool=false notify:bool=true)

    cmd_format_fix
    cmd_format_check

    cmd_lint_fix
    cmd_lint_check

    cmd_audit_fix
    cmd_audit_check

    cmd_syft
    cmd_trivy
    cmd_leaks

    cmd_typos_fix
    cmd_typos_check

    cmd_taplo_fix
    cmd_taplo_check

    cmd_prettier_fix
    cmd_prettier_check

    cmd_tree_fix

    cmd_coverage
    cmd_semver

    (( release )) && [[ -z "${tag}" ]] && tag="$(cmd_guess_tag)"

    cmd_push --tag "${tag}" --release "${release}" "${kwargs[@]}"

    (( sync )) && cmd_sync "${kwargs[@]}"

    (( backup )) && cmd_backup --name "${tag}" "${kwargs[@]}"

}

# Laravel

cmd_pa () {

    php artisan "$@"

}
cmd_pam () {

    php artisan migrate "$@"

}
cmd_pamf () {

    php artisan migrate:fresh "$@"

}
cmd_pams () {

    php artisan migrate --seed "$@"

}
cmd_pas () {

    php artisan serve --host=0.0.0.0 --port=8000 "$@"

}
cmd_paq () {

    php artisan queue:work --tries=3 "$@"

}
cmd_pat () {

    php artisan test "$@"

}
cmd_pak () {

    php artisan tinker "$@"

}
cmd_pah () {

    php artisan horizon "$@"

}
cmd_par () {

    php artisan reverb:start "$@"

}
cmd_pao () {

    php artisan octane:start --server=swoole --host=127.0.0.1 --port=8000 "$@"

}
cmd_paf () {

    php artisan cache:clear
    php artisan config:clear
    php artisan route:clear
    php artisan event:clear
    clear

}

# Node

cmd_np () {

    npm "$@"

}
cmd_npd () {

    npm run dev "$@"

}
cmd_nps () {

    npm start "$@"

}
cmd_npb () {

    npm run build "$@"

}
cmd_npt () {

    npm test "$@"

}
cmd_npi () {

    npm install "$@"

}

# Python

cmd_venv () {

    python3.14 -m venv "${1:-venv}"

}
cmd_venv_nogil () {

    /opt/python-3.14t/bin/python3.14t -m venv "${1:-venv}"

}
cmd_activate () {

    local v="${1:-}"
    [[ -n "${v}" ]] || { [[ -d .venv ]] && v=".venv" || v="venv"; }
    source "${v}/bin/activate"

}

# Docker

cmd_d () {

    docker "$@"

}
cmd_dc () {

    docker compose "$@"

}
cmd_dcu () {

    docker compose up -d "$@"

}
cmd_dcd () {

    docker compose down "$@"

}
cmd_dcl () {

    docker compose logs -f "$@"

}
cmd_dcb () {

    docker compose build "$@"

}
cmd_dcr () {

    docker compose restart "$@"

}

# Public

cmd_run () {

    local host="${CMD_RUN_HOST:-0.0.0.0}" port="${CMD_RUN_PORT:-8000}"

    if [[ -f artisan ]]; then
        php artisan serve --host="${host}" --port="${port}" "$@"
        return 0
    fi
    if [[ -f Cargo.toml ]]; then
        cargo run -- "$@"
        return 0
    fi
    if [[ -f package.json ]]; then
        npm run -s dev -- "$@" 2>/dev/null && return 0
        npm run -s start -- "$@" 2>/dev/null && return 0
        npm start -- "$@" 2>/dev/null && return 0
        return 1
    fi
    if [[ -f manage.py ]]; then
        python manage.py runserver "${host}:${port}" "$@"
        return 0
    fi
    if [[ -f pyproject.toml || -f requirements.txt || -f setup.py || -f setup.cfg || -d .venv || -d venv || -d env ]]; then
        local mod="main"
        if [[ -n "${1-}" && "${1}" != -* ]]; then
            mod="$1"
            shift
        fi
        python -m "${mod}" "$@"
        return 0
    fi
    if [[ -f go.mod ]] || compgen -G "*.go" >/dev/null 2>&1; then
        go run . "$@"
        return 0
    fi
    if [[ -f CMakeLists.txt ]]; then
        cmake -S . -B build && cmake --build build || return 1

        local exe="$(find build -type f -perm -111 \
            ! -path '*/CMakeFiles/*' \
            ! -name 'CMake*' ! -name '*.a' ! -name '*.so' ! -name '*.dylib' ! -name '*.dll' \
            2>/dev/null | head -n 1 || true)"

        [[ -n "${exe}" ]] || return 1
        "${exe}" "$@"
        return 0
    fi
    if [[ -f Makefile || -f makefile || -f GNUmakefile ]]; then
        make run "$@" 2>/dev/null && return 0
        make start "$@" 2>/dev/null && return 0
    fi

    local nullglob_was_set=0
    shopt -q nullglob && nullglob_was_set=1
    shopt -s nullglob

    local -a c=( ./*.c ) cpp=( ./*.cpp )
    (( nullglob_was_set )) || shopt -u nullglob

    if (( ${#c[@]} )); then
        gcc -O2 -Wall -Wextra -std=c11 -o ./a.out "${c[@]}" && ./a.out "$@"
        return 0
    fi
    if (( ${#cpp[@]} )); then
        g++ -O2 -Wall -Wextra -std=c++20 -o ./a.out "${cpp[@]}" && ./a.out "$@"
        return 0
    fi

    return 2

}
cmd_start () {

    local host="${CMD_RUN_HOST:-0.0.0.0}" port="${CMD_RUN_PORT:-8000}"

    if [[ -f artisan ]]; then
        php artisan serve --host="${host}" --port="${port}" "$@"
        return 0
    fi
    if [[ -f Cargo.toml ]]; then
        cargo run -- "$@"
        return 0
    fi
    if [[ -f package.json ]]; then
        npm start -- "$@" 2>/dev/null && return 0
        npm run -s start -- "$@" 2>/dev/null && return 0
        npm run -s dev -- "$@" 2>/dev/null && return 0
        return 1
    fi
    if [[ -f manage.py ]]; then
        python manage.py runserver "${host}:${port}" "$@"
        return 0
    fi
    if [[ -f pyproject.toml || -f requirements.txt || -f setup.py || -f setup.cfg || -d .venv || -d venv || -d env ]]; then
        local mod="main"
        if [[ -n "${1-}" && "${1}" != -* ]]; then
            mod="$1"
            shift
        fi
        python -m "${mod}" "$@"
        return 0
    fi
    if [[ -f go.mod ]] || compgen -G "*.go" >/dev/null 2>&1; then
        go run . "$@"
        return 0
    fi
    if [[ -f CMakeLists.txt ]]; then
        cmake -S . -B build && cmake --build build || return 1

        local exe="$(find build -type f -perm -111 \
            ! -path '*/CMakeFiles/*' \
            ! -name 'CMake*' ! -name '*.a' ! -name '*.so' ! -name '*.dylib' ! -name '*.dll' \
            2>/dev/null | head -n 1 || true)"

        [[ -n "${exe}" ]] || return 1
        "${exe}" "$@"
        return 0
    fi
    if [[ -f Makefile || -f makefile || -f GNUmakefile ]]; then
        make run "$@" 2>/dev/null && return 0
        make start "$@" 2>/dev/null && return 0
    fi

    local nullglob_was_set=0
    shopt -q nullglob && nullglob_was_set=1
    shopt -s nullglob

    local -a c=( ./*.c ) cpp=( ./*.cpp )
    (( nullglob_was_set )) || shopt -u nullglob

    if (( ${#c[@]} )); then
        [[ -x ./a.out ]] || gcc -O2 -Wall -Wextra -std=c11 -o ./a.out "${c[@]}" || return 1
        ./a.out "$@"
        return 0
    fi
    if (( ${#cpp[@]} )); then
        [[ -x ./a.out ]] || g++ -O2 -Wall -Wextra -std=c++20 -o ./a.out "${cpp[@]}" || return 1
        ./a.out "$@"
        return 0
    fi

    printf 'Cannot detect project type in: %s\n' "$(pwd -P)" >&2
    return 2

}
cmd_build () {

    if [[ -f artisan ]]; then
        command -v composer >/dev/null 2>&1 && composer install --no-interaction --no-progress --prefer-dist --optimize-autoloader
        php artisan optimize
        return 0
    fi
    if [[ -f Cargo.toml ]]; then
        cargo build
        return 0
    fi
    if [[ -f package.json ]]; then
        npm run -s build -- "$@"
        return 0
    fi
    if [[ -f pyproject.toml || -f requirements.txt || -f setup.py || -f setup.cfg || -f manage.py || -d .venv || -d venv || -d env ]]; then
        python -m build
        return 0
    fi
    if [[ -f go.mod ]] || compgen -G "*.go" >/dev/null 2>&1; then
        go build ./... "$@"
        return 0
    fi
    if [[ -f CMakeLists.txt ]]; then
        cmake -S . -B build && cmake --build build
        return 0
    fi
    if [[ -f Makefile || -f makefile || -f GNUmakefile ]]; then
        make build "$@" 2>/dev/null && return 0
        make "$@" 2>/dev/null && return 0
    fi

    local nullglob_was_set=0
    shopt -q nullglob && nullglob_was_set=1
    shopt -s nullglob

    local -a c=( ./*.c ) cpp=( ./*.cpp )
    (( nullglob_was_set )) || shopt -u nullglob

    if (( ${#c[@]} )); then
        gcc -O2 -Wall -Wextra -std=c11 -o ./a.out "${c[@]}"
        return 0
    fi
    if (( ${#cpp[@]} )); then
        g++ -O2 -Wall -Wextra -std=c++20 -o ./a.out "${cpp[@]}"
        return 0
    fi

    printf 'Cannot detect project type in: %s\n' "$(pwd -P)" >&2
    return 2

}
cmd_test () {

    if [[ -f artisan ]]; then
        php artisan test "$@"
        return 0
    fi
    if [[ -f Cargo.toml ]]; then
        cargo test -- "$@"
        return 0
    fi
    if [[ -f package.json ]]; then
        npm test -- "$@" 2>/dev/null && return 0
        npm run -s test -- "$@" 2>/dev/null && return 0
        return 1
    fi
    if [[ -f pyproject.toml || -f requirements.txt || -f setup.py || -f setup.cfg || -f manage.py || -d .venv || -d venv || -d env ]]; then
        command -v pytest >/dev/null 2>&1 && pytest -q "$@" && return 0
        python -m unittest "$@"
        return 0
    fi
    if [[ -f go.mod ]] || compgen -G "*.go" >/dev/null 2>&1; then
        go test ./... "$@"
        return 0
    fi
    if [[ -f CMakeLists.txt ]]; then
        [[ -d build ]] || cmake -S . -B build || return 1
        cmake --build build >/dev/null 2>&1 || true
        ctest --test-dir build "$@"
        return 0
    fi
    if [[ -f Makefile || -f makefile || -f GNUmakefile ]]; then
        make test "$@" 2>/dev/null && return 0
    fi

    return 2

}
cmd_clean () {

    if [[ -f artisan ]]; then
        php artisan optimize:clear
        return 0
    fi
    if [[ -f Cargo.toml ]]; then
        cargo clean
        return 0
    fi
    if [[ -f package.json ]]; then
        rm -rf -- node_modules .next dist build
        return 0
    fi
    if [[ -f pyproject.toml || -f requirements.txt || -f setup.py || -f setup.cfg || -f manage.py || -d .venv || -d venv || -d env ]]; then
        find . -type d -name "__pycache__" -prune -exec rm -rf -- {} + 2>/dev/null
        rm -rf -- .pytest_cache .mypy_cache .ruff_cache .tox .venv venv dist build .eggs *.egg-info 2>/dev/null
        return 0
    fi
    if [[ -f go.mod ]] || compgen -G "*.go" >/dev/null 2>&1; then
        rm -rf -- ./bin ./dist ./build 2>/dev/null
        return 0
    fi
    if [[ -f CMakeLists.txt ]]; then
        rm -rf -- build
        return 0
    fi
    if [[ -f Makefile || -f makefile || -f GNUmakefile ]]; then
        make clean "$@" 2>/dev/null && return 0
    fi

    local nullglob_was_set=0
    shopt -q nullglob && nullglob_was_set=1
    shopt -s nullglob

    local -a c=( ./*.c ) cpp=( ./*.cpp )
    (( nullglob_was_set )) || shopt -u nullglob

    if (( ${#c[@]} || ${#cpp[@]} )); then
        rm -rf -- ./a.out ./build
        return 0
    fi

    return 2

}
cmd_show () {

    local name="${1:-}" pat="" self="$$"

    case "${name}" in
        py|python)      pat='python([0-9.]+)?|uvicorn|gunicorn' ;;
        node|js|npm)    pat='node|npm|pnpm|yarn|bun|next|vite|react-scripts' ;;
        laravel|php)    pat='php .*artisan (serve|octane:start|horizon|reverb:start)' ;;
        rust|cargo)     pat='cargo( run)?|target/(debug|release)/' ;;
        go|golang)      pat='(^|[[:space:]/])go([[:space:]]|$)|ListenAndServe|gin\.|echo\.|fiber\.|chi\.|grpc\.' ;;
        c|cxx|cpp|c++)  pat='(^|[[:space:]/])a\.out([[:space:]]|$)|(^|[[:space:]/])(clang\+\+|g\+\+|clang|gcc)([[:space:]]|$)|cmake|ctest' ;;
        mk|make)        pat='(^|[[:space:]/])make([[:space:]]|$)' ;;
        *)              pat="$(printf '%s' "${name}" | sed 's/[][(){}.^$*+?|\\]/\\&/g')" ;;
    esac

    ps -eo pid=,user=,comm=,args= \
        | awk -v u="${USER}" -v self="${self}" -v pat="${pat}" '
            BEGIN { printf "%-7s %-12s %-18s %s\n", "PID", "USER", "CMD", "ARGS" }
            $2 == u && $1 != self && $0 ~ pat {
                pid=$1; user=$2; cmd=$3;
                $1=""; $2=""; $3="";
                sub(/^  +/, "", $0);
                printf "%-7s %-12s %-18s %s\n", pid, user, cmd, $0
            }
        '

}
cmd_kill () {

    local name="${1:-}" pat="" self="$$"
    local -a pids=()

    case "${name}" in
        py|python)      pat='python([0-9.]+)?|uvicorn|gunicorn' ;;
        node|js|npm)    pat='node|npm|pnpm|yarn|bun|next|vite|react-scripts' ;;
        laravel|php)    pat='php .*artisan (serve|octane:start|horizon|reverb:start)' ;;
        rust|cargo)     pat='cargo( run)?|target/(debug|release)/' ;;
        go|golang)      pat='(^|[[:space:]/])go([[:space:]]|$)|ListenAndServe|gin\.|echo\.|fiber\.|chi\.|grpc\.' ;;
        c|cxx|cpp|c++)  pat='(^|[[:space:]/])a\.out([[:space:]]|$)|(^|[[:space:]/])(clang\+\+|g\+\+|clang|gcc)([[:space:]]|$)|cmake|ctest' ;;
        mk|make)        pat='(^|[[:space:]/])make([[:space:]]|$)' ;;
        *)              pat="$(printf '%s' "${name}" | sed 's/[][(){}.^$*+?|\\]/\\&/g')" ;;
    esac

    while IFS= read -r pid; do
        [[ -n "${pid}" ]] || continue
        pids+=( "${pid}" )
    done < <(ps -eo pid=,user=,args= | awk -v u="${USER}" -v self="${self}" -v pat="${pat}" '$2 == u && $1 != self && $0 ~ pat { print $1 }')

    (( ${#pids[@]} )) || return 0
    kill -9 -- "${pids[@]}" 2>/dev/null || true

}

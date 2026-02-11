#!/usr/bin/env bash

semver_baseline () {

    local baseline="${1:-}"
    local remote="${2:-origin}"

    [[ -n "${baseline}" ]] && { printf '%s' "${baseline}"; return 0; }
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

    if is_ci_pull; then

        local base="${GITHUB_BASE_REF:-}"
        [[ -n "${base}" ]] || die "Missing GITHUB_BASE_REF. Provide --baseline <rev>."

        run git fetch --no-tags "${remote}" "${base}:refs/remotes/${remote}/${base}" >/dev/null 2>&1 || die "Failed: git fetch."
        printf '%s' "${remote}/${base}"
        return 0

    fi
    if is_ci_push; then

        run git fetch --tags --force --prune "${remote}" >/dev/null 2>&1 || true

        baseline="$(
            git tag --list 'v*' --sort=-v:refname |
            grep -E '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' |
            grep -F -x -v "${GITHUB_REF_NAME:-}" |
            head -n 1 || true
        )"

        printf '%s' "${baseline}"
        return 0

    fi

    local def="$(git symbolic-ref -q "refs/remotes/${remote}/HEAD" 2>/dev/null || true)"
    def="${def#refs/remotes/${remote}/}"
    [[ -n "${def}" ]] || def="main"

    run git fetch --no-tags "${remote}" "${def}:refs/remotes/${remote}/${def}" >/dev/null 2>&1 || true
    git show-ref --verify --quiet "refs/remotes/${remote}/${def}" || return 0

    printf '%s' "${remote}/${def}"

}

semver_rust () {

    ensure_pkg cargo cargo-semver-checks
    source <(parse "$@" -- base)

    local -a cmd=()

    [[ -n "${base}" ]] || base="$(semver_baseline)"
    [[ -n "${base}" ]] && cmd+=( --baseline-rev "${base}" )

    run cargo semver-checks "${cmd[@]}" "${kwargs[@]}"

}
semver_go () {

    ensure_pkg go gorelease
    source <(parse "$@" -- base)

    local -a cmd=()

    [[ -n "${base}" ]] || base="$(semver_baseline)"
    [[ -n "${base}" ]] && cmd+=( -base="${base}" )

    run gorelease "${cmd[@]}" "${kwargs[@]}"

}
semver_py () {

    ensure_pkg python griffe
    source <(parse "$@" -- base)

    local -a cmd=()

    [[ -n "${base}" ]] || base="$(semver_baseline)"
    [[ -n "${base}" ]] && cmd+=( -b HEAD -a "${base}" )

    run griffe check "${cmd[@]}" "${kwargs[@]}"

}
semver_node () {

    ensure_pkg npx
    source <(parse "$@" -- base)

    local -a cmd=( npx -y @microsoft/api-extractor )
    [[ -x node_modules/.bin/api-extractor ]] && cmd=( node_modules/.bin/api-extractor )

    [[ -d dist ]] || [[ -d lib ]] || run npm run build

    is_ci || [[ -f api-extractor.json ]] || run "${cmd[@]}" init
    is_ci && cmd+=( run --verbose ) || cmd+=( run --verbose --local )

    run "${cmd[@]}" "${kwargs[@]}"

}
semver_php () {

    ensure_pkg php
    source <(parse "$@" -- base)

    local -a cmd=( roave-backward-compatibility-check )
    [[ -x vendor/bin/roave-backward-compatibility-check ]] && cmd=( vendor/bin/roave-backward-compatibility-check )

    [[ -n "${base}" ]] || base="$(semver_baseline)"
    [[ -n "${base}" ]] && cmd+=( --from="${base}" --to="HEAD" )

    run "${cmd[@]}" "${kwargs[@]}"

}

cmd_semver () {

    case "$(which_lang)" in
        rust) semver_rust "$@" ;;
        go)   semver_go   "$@" ;;
        py)   semver_py   "$@" ;;
        node) semver_node "$@" ;;
        php)  semver_php  "$@" ;;
        *)    die "semver: unknown root manager" ;;
    esac

}

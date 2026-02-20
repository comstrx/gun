#!/usr/bin/env bash

semver_normalize () {

    local v="${1:-}"

    v="${v#v}"
    v="${v%"${v##*[![:space:]]}"}"
    v="${v#"${v%%[![:space:]]*}"}"

    printf '%s' "${v}"

}
semver_validate () {

    local v=""
    v="$(semver_normalize "${1:-}")"

    [[ -n "${v}" ]] || return 1
    [[ "${v}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-][0-9A-Za-z.-]+)?([+][0-9A-Za-z.-]+)?$ ]]

}
semver_triplet () {

    local v="" a="" b="" c=""

    v="$(semver_normalize "${1:-}")"

    [[ "${v}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]] || return 1

    a="${BASH_REMATCH[1]}"
    b="${BASH_REMATCH[2]}"
    c="${BASH_REMATCH[3]}"

    printf '%s %s %s' "${a}" "${b}" "${c}"

}
semver_major_bumped () {

    local old="" cur="" om="" on="" op="" cm="" cn="" cp=""
    local old_major="" old_minor="" cur_major="" cur_minor=""

    old="$(semver_normalize "${1:-}")"
    cur="$(semver_normalize "${2:-}")"

    read -r om on op < <(semver_triplet "${old}") || return 1
    read -r cm cn cp < <(semver_triplet "${cur}") || return 1

    old_major="${om}"
    old_minor="${on}"
    cur_major="${cm}"
    cur_minor="${cn}"

    if (( cur_major > old_major )); then
        return 0
    fi

    if (( old_major == 0 )); then

        if (( cur_minor > old_minor )); then
            return 0
        fi

    fi

    return 1

}
semver_require_major_bump () {

    local lang="${1:-}" cur="${2:-}" old="${3:-}"

    [[ -n "${cur}" ]] || die "semver: ${lang} missing current version"
    semver_validate "${cur}" || die "semver: ${lang} invalid version (${cur})"

    [[ -n "${old}" ]] || die "semver: ${lang} missing baseline version"
    semver_validate "${old}" || die "semver: ${lang} invalid baseline version (${old})"

    [[ "${cur}" != "${old}" ]] || die "semver: ${lang} version not bumped (${old})"
    semver_major_bumped "${old}" "${cur}" || die "semver: ${lang} breaking change requires major bump (${old} -> ${cur})"

}
semver_baseline () {

    local baseline="${1:-}" remote="${2:-origin}" def="" base=""

    [[ -n "${baseline}" ]] && { printf '%s' "${baseline}"; return 0; }
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

    if is_ci_pull; then

        base="${GITHUB_BASE_REF:-}"
        [[ -n "${base}" ]] || die "semver: missing GITHUB_BASE_REF (or pass --base <rev>)"

        git show-ref --verify --quiet "refs/remotes/${remote}/${base}" 2>/dev/null || \
            run git fetch --no-tags "${remote}" "${base}:refs/remotes/${remote}/${base}" >/dev/null 2>&1 || \
                die "semver: git fetch failed"

        printf '%s' "${remote}/${base}"
        return 0

    fi

    def="$(git symbolic-ref -q "refs/remotes/${remote}/HEAD" 2>/dev/null || true)"
    def="${def#refs/remotes/${remote}/}"
    [[ -n "${def}" ]] || def="main"

    git show-ref --verify --quiet "refs/remotes/${remote}/${def}" 2>/dev/null || \
        run git fetch --no-tags "${remote}" "${def}:refs/remotes/${remote}/${def}" >/dev/null 2>&1 || true

    git show-ref --verify --quiet "refs/remotes/${remote}/${def}" 2>/dev/null || return 0

    printf '%s' "${remote}/${def}"

}
semver_breaking_diff () {

    local base="${1:-}" pattern="${2:-}"
    shift 2 || true

    [[ -n "${base}" ]] || return 1
    [[ $# -gt 0 ]] || return 1

    git diff --unified=0 "${base}...HEAD" -- "$@" 2>/dev/null \
        | grep -E '^-|^deleted file mode' \
        | grep -Ev '^--- ' \
        | grep -Eq "${pattern}"

}
semver_json_version () {

    local file="${1:-}" v=""

    [[ -f "${file}" ]] || { printf '%s' ""; return 0; }

    if has node; then
        v="$(node -p "require('./${file}').version" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }
    fi

    if has python3; then
        v="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "${file}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }
    fi

    v="$(grep -m1 -E '"version"[[:space:]]*:[[:space:]]*"' "${file}" 2>/dev/null | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)"
    printf '%s' "${v}"

}

semver_pyproject_version_file () {

    local v=""

    [[ -f pyproject.toml ]] || { printf '%s' ""; return 0; }

    if has python3; then
        v="$(python3 -c 'import tomllib; print(tomllib.load(open("pyproject.toml","rb"))["project"]["version"])' 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }
    fi

    v="$(grep -n -m1 -E '^[[:space:]]*version[[:space:]]*=[[:space:]]*["'\'']' pyproject.toml 2>/dev/null | sed -E 's/.*version[[:space:]]*=[[:space:]]*(["'\''])([^"'\'']+)\1.*/\2/' || true)"
    printf '%s' "${v}"

}
semver_pyproject_version_blob () {

    local v=""

    if has python3; then
        v="$(python3 -c 'import sys,tomllib; data=sys.stdin.buffer.read(); print(tomllib.loads(data.decode())["project"]["version"])' 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }
    fi

    v="$(grep -m1 -E '^[[:space:]]*version[[:space:]]*=[[:space:]]*["'\'']' 2>/dev/null | sed -E 's/.*version[[:space:]]*=[[:space:]]*(["'\''])([^"'\'']+)\1.*/\2/' || true)"
    printf '%s' "${v}"

}
semver_xmake_version_file () {

    local v=""

    [[ -f xmake.lua ]] || { printf '%s' ""; return 0; }

    v="$(grep -m1 -E "set_version\\((['\"]).*\\1\\)" xmake.lua 2>/dev/null | sed -E "s/.*set_version\\((['\"])([^'\"]+)\\1\\).*/\\2/" || true)"
    printf '%s' "${v}"

}
semver_xmake_version_blob () {

    local v=""

    v="$(grep -m1 -E "set_version\\((['\"]).*\\1\\)" 2>/dev/null | sed -E "s/.*set_version\\((['\"])([^'\"]+)\\1\\).*/\\2/" || true)"
    printf '%s' "${v}"

}
semver_conan_version_file () {

    local v=""

    [[ -f conanfile.py ]] || { printf '%s' ""; return 0; }

    v="$(grep -m1 -E '^[[:space:]]*version[[:space:]]*=' conanfile.py 2>/dev/null | sed -E "s/^[^'\"]*(['\"])([^'\"]+)\\1.*$/\\2/" || true)"
    printf '%s' "${v}"

}
semver_conan_version_blob () {

    local v=""

    v="$(grep -m1 -E '^[[:space:]]*version[[:space:]]*=' 2>/dev/null | sed -E "s/^[^'\"]*(['\"])([^'\"]+)\\1.*$/\\2/" || true)"
    printf '%s' "${v}"

}

semver_c () {

    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}" cur="" old=""

    [[ -n "${base}" ]] || { warn "semver: c no baseline"; return 0; }

    semver_breaking_diff "${base}" '^-|^deleted file mode' include '*.h' || return 0

    if [[ -f VERSION ]]; then
        cur="$(tr -d '[:space:]' < VERSION 2>/dev/null || true)"
        old="$(git show "${base}:VERSION" 2>/dev/null | tr -d '[:space:]' || true)"
    elif [[ -f xmake.lua ]]; then
        cur="$(semver_xmake_version_file)"
        old="$(git show "${base}:xmake.lua" 2>/dev/null | semver_xmake_version_blob || true)"
    elif [[ -f conanfile.py ]]; then
        cur="$(semver_conan_version_file)"
        old="$(git show "${base}:conanfile.py" 2>/dev/null | semver_conan_version_blob || true)"
    else
        die "semver: c needs VERSION/xmake.lua/conanfile.py"
    fi

    semver_require_major_bump "c" "${cur}" "${old}"

}
semver_cpp () {

    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}" cur="" old=""

    [[ -n "${base}" ]] || { warn "semver: cpp no baseline"; return 0; }

    semver_breaking_diff "${base}" '^-|^deleted file mode' include '*.hpp' '*.hh' '*.hxx' '*.inl' '*.ipp' '*.tpp' '*.ixx' '*.h' || return 0

    if [[ -f VERSION ]]; then
        cur="$(tr -d '[:space:]' < VERSION 2>/dev/null || true)"
        old="$(git show "${base}:VERSION" 2>/dev/null | tr -d '[:space:]' || true)"
    elif [[ -f xmake.lua ]]; then
        cur="$(semver_xmake_version_file)"
        old="$(git show "${base}:xmake.lua" 2>/dev/null | semver_xmake_version_blob || true)"
    elif [[ -f conanfile.py ]]; then
        cur="$(semver_conan_version_file)"
        old="$(git show "${base}:conanfile.py" 2>/dev/null | semver_conan_version_blob || true)"
    else
        die "semver: cpp needs VERSION/xmake.lua/conanfile.py"
    fi

    semver_require_major_bump "cpp" "${cur}" "${old}"

}
semver_zig () {

    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}" cur="" old=""

    [[ -n "${base}" ]] || { warn "semver: zig no baseline"; return 0; }
    [[ -f build.zig.zon ]] || { warn "semver: zig needs build.zig.zon"; return 0; }

    semver_breaking_diff "${base}" '^-|^deleted file mode' build.zig.zon build.zig src '*.zig' || return 0

    cur="$(grep -m1 -E '^[[:space:]]*(\.version|version)[[:space:]]*=[[:space:]]*"' build.zig.zon 2>/dev/null | sed -E 's/^[^"]*"([^"]+)".*$/\1/' || true)"
    old="$(git show "${base}:build.zig.zon" 2>/dev/null | grep -m1 -E '^[[:space:]]*(\.version|version)[[:space:]]*=[[:space:]]*"' 2>/dev/null | sed -E 's/^[^"]*"([^"]+)".*$/\1/' || true)"

    semver_require_major_bump "zig" "${cur}" "${old}"

}
semver_rust () {

    ensure_pkg cargo cargo-semver-checks
    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}"

    [[ -n "${base}" ]] || { warn "semver: rust no baseline"; return 0; }
    run cargo semver-checks --baseline-rev "${base}" "${kwargs[@]}"

}
semver_go () {

    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}" cur="" old=""

    [[ -n "${base}" ]] || { warn "semver: go no baseline"; return 0; }
    [[ -f VERSION ]] || { warn "semver: go needs VERSION"; return 0; }

    semver_breaking_diff "${base}" '^-.*\b(func[[:space:]]*(\([^)]*\)[[:space:]]*)?[A-Z][A-Za-z0-9_]*\b|type[[:space:]]+[A-Z][A-Za-z0-9_]*\b|const[[:space:]]+[A-Z][A-Za-z0-9_]*\b|var[[:space:]]+[A-Z][A-Za-z0-9_]*\b)' '*.go' || return 0

    cur="$(tr -d '[:space:]' < VERSION 2>/dev/null || true)"
    old="$(git show "${base}:VERSION" 2>/dev/null | tr -d '[:space:]' || true)"

    semver_require_major_bump "go" "${cur}" "${old}"

}
semver_python () {

    ensure_pkg python3 griffe
    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}" cur="" old=""

    [[ -n "${base}" ]] || { warn "semver: python no baseline"; return 0; }

    run griffe check -b HEAD -a "${base}" "${kwargs[@]}" || {

        if [[ -f pyproject.toml ]]; then
            cur="$(semver_pyproject_version_file)"
            old="$(git show "${base}:pyproject.toml" 2>/dev/null | semver_pyproject_version_blob || true)"
        elif [[ -f VERSION ]]; then
            cur="$(tr -d '[:space:]' < VERSION 2>/dev/null || true)"
            old="$(git show "${base}:VERSION" 2>/dev/null | tr -d '[:space:]' || true)"
        else
            die "semver: python breaking change detected, but needs pyproject.toml or VERSION to gate"
        fi

        semver_require_major_bump "python" "${cur}" "${old}"

    }

}
semver_node () {

    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}" cur="" old=""

    [[ -n "${base}" ]] || { warn "semver: node no baseline"; return 0; }
    [[ -f package.json ]] || { warn "semver: node needs package.json"; return 0; }

    if [[ -d types ]] || compgen -G "*.d.ts" >/dev/null; then
        semver_breaking_diff "${base}" '^-.*\b(export|declare|interface|type|class|enum|namespace|function|const|let|var)\b' types '*.d.ts' || return 0
    else
        semver_breaking_diff "${base}" '^-.*\b(export|module\.exports|exports\.)' src '*.ts' '*.mts' '*.cts' '*.js' '*.mjs' '*.cjs' || return 0
    fi

    cur="$(semver_json_version package.json)"

    old=""
    if has node; then
        old="$(git show "${base}:package.json" 2>/dev/null | node -p 'JSON.parse(require("fs").readFileSync(0,"utf8")).version' 2>/dev/null || true)"
    elif has python3; then
        old="$(git show "${base}:package.json" 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])' 2>/dev/null || true)"
    fi
    [[ -n "${old}" ]] || old="$(git show "${base}:package.json" 2>/dev/null | grep -m1 -E '"version"[[:space:]]*:[[:space:]]*"' 2>/dev/null | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)"

    semver_require_major_bump "node" "${cur}" "${old}"

}
semver_bun () {

    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}" cur="" old=""

    [[ -n "${base}" ]] || { warn "semver: bun no baseline"; return 0; }
    [[ -f package.json ]] || { warn "semver: bun needs package.json"; return 0; }

    if [[ -d types ]] || compgen -G "*.d.ts" >/dev/null; then
        semver_breaking_diff "${base}" '^-.*\b(export|declare|interface|type|class|enum|namespace|function|const|let|var)\b' types '*.d.ts' || return 0
    else
        semver_breaking_diff "${base}" '^-.*\b(export|module\.exports|exports\.)' src '*.ts' '*.mts' '*.cts' '*.js' '*.mjs' '*.cjs' || return 0
    fi

    cur="$(semver_json_version package.json)"

    old=""
    if has bun; then
        old="$(git show "${base}:package.json" 2>/dev/null | bun -e 'console.log(JSON.parse(require("fs").readFileSync(0,"utf8")).version)' 2>/dev/null || true)"
    elif has node; then
        old="$(git show "${base}:package.json" 2>/dev/null | node -p 'JSON.parse(require("fs").readFileSync(0,"utf8")).version' 2>/dev/null || true)"
    elif has python3; then
        old="$(git show "${base}:package.json" 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])' 2>/dev/null || true)"
    fi
    [[ -n "${old}" ]] || old="$(git show "${base}:package.json" 2>/dev/null | grep -m1 -E '"version"[[:space:]]*:[[:space:]]*"' 2>/dev/null | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)"

    semver_require_major_bump "bun" "${cur}" "${old}"

}
semver_php () {

    ensure_pkg php roave-backward-compatibility-check
    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}"
    local -a cmd=( roave-backward-compatibility-check )
    local cur="" old=""

    [[ -x vendor/bin/roave-backward-compatibility-check ]] && cmd=( vendor/bin/roave-backward-compatibility-check )
    [[ -n "${base}" ]] || { warn "semver: php no baseline"; return 0; }

    run "${cmd[@]}" --from="${base}" --to=HEAD "${kwargs[@]}" || {

        if [[ -f VERSION ]]; then
            cur="$(tr -d '[:space:]' < VERSION 2>/dev/null || true)"
            old="$(git show "${base}:VERSION" 2>/dev/null | tr -d '[:space:]' || true)"
        else
            die "semver: php breaking change detected, but needs VERSION to gate"
        fi

        semver_require_major_bump "php" "${cur}" "${old}"

    }

}
semver_csharp () {

    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}" cur="" old="" csproj=""

    [[ -n "${base}" ]] || { warn "semver: csharp no baseline"; return 0; }

    semver_breaking_diff "${base}" '^-.*\bpublic\b|^deleted file mode' '*.cs' || return 0

    if [[ -f Directory.Build.props ]]; then
        cur="$(grep -m1 -E '<(PackageVersion|Version)>' Directory.Build.props 2>/dev/null | sed -E 's/.*<(PackageVersion|Version)>([^<]+)<\/(PackageVersion|Version)>.*/\2/' || true)"
        old="$(git show "${base}:Directory.Build.props" 2>/dev/null | grep -m1 -E '<(PackageVersion|Version)>' 2>/dev/null | sed -E 's/.*<(PackageVersion|Version)>([^<]+)<\/(PackageVersion|Version)>.*/\2/' || true)"
    else
        csproj="$(find . -maxdepth 4 -name '*.csproj' 2>/dev/null | head -n 1 || true)"
        [[ -n "${csproj}" ]] || die "semver: csharp needs Directory.Build.props or *.csproj"

        cur="$(grep -m1 -E '<(PackageVersion|Version)>' "${csproj}" 2>/dev/null | sed -E 's/.*<(PackageVersion|Version)>([^<]+)<\/(PackageVersion|Version)>.*/\2/' || true)"
        old="$(git show "${base}:${csproj}" 2>/dev/null | grep -m1 -E '<(PackageVersion|Version)>' 2>/dev/null | sed -E 's/.*<(PackageVersion|Version)>([^<]+)<\/(PackageVersion|Version)>.*/\2/' || true)"
    fi

    semver_require_major_bump "csharp" "${cur}" "${old}"

}
semver_java () {

    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}" cur="" old=""

    [[ -n "${base}" ]] || { warn "semver: java no baseline"; return 0; }

    semver_breaking_diff "${base}" '^-.*\b(public|protected)\b|^deleted file mode' src '*.java' || return 0

    if [[ -f gradle.properties ]]; then
        cur="$(grep -m1 -E '^[[:space:]]*version=' gradle.properties 2>/dev/null | sed -E 's/^[[:space:]]*version=//' || true)"
        old="$(git show "${base}:gradle.properties" 2>/dev/null | grep -m1 -E '^[[:space:]]*version=' 2>/dev/null | sed -E 's/^[[:space:]]*version=//' || true)"
    elif [[ -f pom.xml ]]; then
        cur="$(grep -m1 -E '<version>' pom.xml 2>/dev/null | sed -E 's/.*<version>([^<]+)<\/version>.*/\1/' || true)"
        old="$(git show "${base}:pom.xml" 2>/dev/null | grep -m1 -E '<version>' 2>/dev/null | sed -E 's/.*<version>([^<]+)<\/version>.*/\1/' || true)"
    else
        die "semver: java needs gradle.properties or pom.xml"
    fi

    semver_require_major_bump "java" "${cur}" "${old}"

}
semver_mojo () {

    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}" cur="" old=""

    [[ -n "${base}" ]] || { warn "semver: mojo no baseline"; return 0; }
    [[ -f pixi.toml ]] || { warn "semver: mojo needs pixi.toml"; return 0; }

    semver_breaking_diff "${base}" '^-|^deleted file mode' src pixi.toml '*.mojo' || return 0

    cur="$(grep -m1 -E '^[[:space:]]*version[[:space:]]*=[[:space:]]*"' pixi.toml 2>/dev/null | sed -E 's/^[^"]*"([^"]+)".*$/\1/' || true)"
    old="$(git show "${base}:pixi.toml" 2>/dev/null | grep -m1 -E '^[[:space:]]*version[[:space:]]*=[[:space:]]*"' 2>/dev/null | sed -E 's/^[^"]*"([^"]+)".*$/\1/' || true)"

    semver_require_major_bump "mojo" "${cur}" "${old}"

}
semver_dart () {

    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}" cur="" old=""

    [[ -n "${base}" ]] || { warn "semver: dart no baseline"; return 0; }
    [[ -f pubspec.yaml ]] || { warn "semver: dart needs pubspec.yaml"; return 0; }

    semver_breaking_diff "${base}" '^-.*\b(class|typedef|enum|extension|mixin|external|factory|get|set|operator|export)\b|^deleted file mode' lib '*.dart' || return 0

    cur="$(grep -m1 -E '^[[:space:]]*version:[[:space:]]*' pubspec.yaml 2>/dev/null | sed -E 's/^[[:space:]]*version:[[:space:]]*([^[:space:]]+).*/\1/' || true)"
    old="$(git show "${base}:pubspec.yaml" 2>/dev/null | grep -m1 -E '^[[:space:]]*version:[[:space:]]*' 2>/dev/null | sed -E 's/^[[:space:]]*version:[[:space:]]*([^[:space:]]+).*/\1/' || true)"

    semver_require_major_bump "dart" "${cur}" "${old}"

}
semver_lua () {

    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}" cur="" old=""

    [[ -n "${base}" ]] || { warn "semver: lua no baseline"; return 0; }
    [[ -f VERSION ]] || { warn "semver: lua needs VERSION"; return 0; }

    semver_breaking_diff "${base}" '^-.*\b(function|return|local)\b|^deleted file mode' src lua '*.lua' || return 0

    cur="$(tr -d '[:space:]' < VERSION 2>/dev/null || true)"
    old="$(git show "${base}:VERSION" 2>/dev/null | tr -d '[:space:]' || true)"

    semver_require_major_bump "lua" "${cur}" "${old}"

}
semver_bash () {

    source <(parse "$@" -- base)

    local base="${base:-$(semver_baseline)}" cur="" old=""

    [[ -n "${base}" ]] || { warn "semver: bash no baseline"; return 0; }
    [[ -f VERSION ]] || { warn "semver: bash needs VERSION"; return 0; }

    semver_breaking_diff "${base}" '^-.*\b(cmd_|run_|gun_|export[[:space:]]+function|function[[:space:]]+[a-zA-Z0-9_]+)\b|^deleted file mode' scripts module '*.sh' || return 0

    cur="$(tr -d '[:space:]' < VERSION 2>/dev/null || true)"
    old="$(git show "${base}:VERSION" 2>/dev/null | tr -d '[:space:]' || true)"

    semver_require_major_bump "bash" "${cur}" "${old}"

}

cmd_semver () {

    case "$(which_lang)" in
        c)      semver_c      "$@" ;;
        cpp)    semver_cpp    "$@" ;;
        zig)    semver_zig    "$@" ;;
        rust)   semver_rust   "$@" ;;
        go)     semver_go     "$@" ;;
        python) semver_python "$@" ;;
        node)   semver_node   "$@" ;;
        bun)    semver_bun    "$@" ;;
        php)    semver_php    "$@" ;;
        csharp) semver_csharp "$@" ;;
        java)   semver_java   "$@" ;;
        mojo)   semver_mojo   "$@" ;;
        dart)   semver_dart   "$@" ;;
        lua)    semver_lua    "$@" ;;
        bash)   semver_bash   "$@" ;;
        *)      die "semver: unknown root manager" ;;
    esac

}

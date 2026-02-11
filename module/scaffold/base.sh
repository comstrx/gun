#!/usr/bin/env bash

excluded_files () {

    local lang="${1:-}"
    local -a excluded=()

    lang="${lang##*/}"
    lang="${lang%%[[:space:]]*}"

    case "${lang,,}" in
        rust*|crate*|workspace*)       excluded=( biome golang php pint py ruff ) ;;
        go*|golang*)                   excluded=( biome php pint py ruff clippy deny rust ) ;;
        py*|django*|flask*|fastapi*)   excluded=( biome golang php pint clippy deny rust ) ;;
        php*|laravel*)                 excluded=( biome golang py ruff clippy deny rust ) ;;
        node*|express*|react*|next*)   excluded=( golang php pint py ruff clippy deny rust ) ;;
        *)                             excluded=( biome golang php pint py ruff clippy deny rust );
    esac

    printf '%s\n' "${excluded[@]}"

}
copy_missing_files () {

    ensure_pkg mkdir find cp

    local base="${1:-}" dest="${2:-}" lang="${3:-}" p="" rel="" d="" bn="" pat=""
    local -a excluded=()

    [[ -n "${base}" && -d "${base}" ]] || return 0
    [[ -n "${dest}" && -d "${dest}" ]] || die "dest dir not found: ${dest}"

    mapfile -t excluded < <(excluded_files "${lang}")

    while IFS= read -r -d '' p; do

        rel="${p#${base}/}"
        [[ -n "${rel}" ]] || continue

        bn="${rel##*/}"
        for pat in "${excluded[@]}"; do
            [[ "${bn}" == .${pat}* || "${bn}" == *.${pat}* ]] && continue 2
        done

        d="${dest}/${rel}"
        [[ -e "${d}" ]] && continue

        if [[ "${d}" == */* ]]; then mkdir -p "${d%/*}" 2>/dev/null || die "mkdir failed: ${d}"; fi
        cp -pPR "${p}" "${d}" 2>/dev/null || cp -a "${p}" "${d}" 2>/dev/null || die "copy failed: ${p} -> ${d}"

    done < <(find "${base}" -mindepth 1 \( -type f -o -type l \) -print0)

}

resolve_template () {

    local t="${1:-}" dir="${2:-}" p="" n="" nl="" a="" b=""
    local exact="" first="" second="" nullglob_was_set=0

    [[ -n "${t}" ]] || { printf '%s\n' empty; return; }
    t="${t,,}"
    a="${t%%-*}"
    [[ "${t}" == *-* ]] && b="${t#*-}" || b=""

    shopt -q nullglob && nullglob_was_set=1
    shopt -s nullglob

    for p in "${dir}"/*/; do

        n="${p%/}"; n="${n##*/}"
        nl="${n,,}"

        [[ -z "${exact}" && "${nl}" == "${t}" ]] && exact="${n}"
        [[ -z "${first}" && "${nl}" == "${a}" ]] && first="${n}"
        [[ -z "${second}" && -n "${b}" && "${nl}" == "${b}" ]] && second="${n}"

    done

    (( nullglob_was_set )) || shopt -u nullglob
    printf '%s\n' "${exact:-${first:-${second:-empty}}}"

}
copy_template () {

    ensure_pkg mkdir find tar grep

    local src="${1:-}" dest="${2:-}"
    local -a tar_out=()

    [[ -n "${src}" && -d "${src}" ]] || die "src dir not found: ${src}"
    [[ -n "${dest}" ]] || die "empty dest"

    mkdir -p -- "${dest}" 2>/dev/null || die "cannot create dir: ${dest} (pass --dir or fix permissions)"
    [[ -n "$(find "${dest}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null || true)" ]] && die "target dir not empty: ${dest}"

    tar_out=( tar -C "${dest}" -xf - )
    ( tar --help 2>/dev/null || true ) | grep -q -- '--no-same-owner' && tar_out=( tar --no-same-owner -C "${dest}" -xf - )

    tar -C "${src}" -cf - . | "${tar_out[@]}" || die "copy failed: ${src} -> ${dest}"

}

replace_all () {

    ensure_pkg find mktemp rm perl xargs

    local root="${1:-}" map_name="${2:-}" ig="" f="" any=0 kv="" k=""

    [[ -n "${root}" && -d "${root}" ]] || die "replace: root dir not found: ${root}"
    [[ -n "${map_name}" ]] || die "replace: missing map name"

    local -n map="${map_name}"
    ((${#map[@]})) || return 0

    local -a ignore_list=( ".git" "target" "node_modules" "dist" "build" ".next" ".venv" "venv" ".vscode" "__pycache__" )
    local -a find_cmd=( find "${root}" -type d "(" )

    kv="$(mktemp "${TMPDIR:-/tmp}/replace.map.XXXXXX")" || die "replace: mktemp failed"
    trap 'rm -rf -- "${kv}" 2>/dev/null || true; trap - RETURN' RETURN
    : > "${kv}" || { rm -f "${kv}" 2>/dev/null || true; die "replace: cannot write tmp file"; }

    for k in "${!map[@]}"; do
        [[ "${k}" != *$'\0'* && "${map["${k}"]}" != *$'\0'* ]] || die "replace: NUL not allowed in map"
        printf '%s\0%s\0' "${k}" "${map["${k}"]}" >> "${kv}"
    done

    for ig in "${ignore_list[@]}"; do find_cmd+=( -name "${ig}" -o ); done
    find_cmd+=( -false ")" -prune -o -type f ! -lname '*' -print0 )

    while IFS= read -r -d '' f; do any=1; break; done < <("${find_cmd[@]}")
    (( any )) || { rm -f "${kv}" 2>/dev/null || true; return 0; }

    "${find_cmd[@]}" | KV_FILE="${kv}" xargs -0 perl -0777 -i -pe '
        BEGIN {
            our %map = ();
            our $re  = "";

            my $kv = $ENV{KV_FILE} // "";
            open my $fh, "<", $kv or die "kv open failed: $kv";
            local $/;
            my $buf = <$fh>;
            close $fh;

            my @p = split(/\0/, $buf, -1);
            pop @p if @p && $p[-1] eq "";
            die "kv pairs mismatch\n" if @p % 2;

            for (my $i = 0; $i < @p; $i += 2) {
                $map{$p[$i]} = $p[$i + 1];
            }

            my @keys = sort { length($b) <=> length($a) } keys %map;
            $re = @keys ? join("|", map { quotemeta($_) } @keys) : "";
        }

        if ( $re ne "" && index($_, "\0") == -1 ) {
            s/($re)/$map{$1}/g;
        }
    ' || { rm -f "${kv}" 2>/dev/null || true; die "replace failed"; }

}
default_branch () {

    ensure_pkg git
    local root="${1:-}" b=""

    if has git && [[ -e "${root}/.git" ]]; then

        b="$(cd -- "${root}" && git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)"
        b="${b#origin/}"

        [[ -n "${b}" ]] || b="$(cd -- "${root}" && git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
        [[ "${b}" == "HEAD" ]] && b=""

    fi

    [[ -n "${b}" ]] || b="main"
    printf '%s' "${b}"

}
prepare_placeholders () {

    local root="${1:-}" name="${2:-}" alias="${3:-}" user="${4:-}" repo="${5:-}" branch="${6:-}" description="${7:-}"
    local discord_url="${8:-}" docs_url="${9:-}" site_url="${10:-}" github_host="${11:-}"

    cd -- "${root}"
    [[ -n "${branch}" ]] || branch="$(default_branch "${root}")"
    [[ -n "${github_host}" ]] || github_host="https://github.com"
    [[ "${github_host}" == *"://"* ]] || github_host="https://${github_host}"

    local -A ph_map=()

    append () {

        local k="${1-}" v="${2-}"
        [[ -n "${k}" && -n "${v}" ]] || return 0

        ph_map["__${k,,}__"]="${v}"
        ph_map["__${k^^}__"]="${v}"
        ph_map["--${k,,}--"]="${v}"
        ph_map["--${k^^}--"]="${v}"
        ph_map["{{${k,,}}}"]="${v}"
        ph_map["{{${k^^}}}"]="${v}"

    }
    blob_gh_url () {

        local repo_url="${1:-}" branch="${2:-}" rel="${3:-}"
        printf '%s/blob/%s/%s' "${repo_url}" "${branch}" "${rel#/}"

    }
    tree_gh_url () {

        local repo_url="${1:-}" branch="${2:-}" rel="${3:-}"
        printf '%s/tree/%s/%s' "${repo_url}" "${branch}" "${rel#/}"

    }

    append "year" "$(date +%Y)"
    append "alias" "${alias}"
    append "branch" "${branch}"
    append "user" "${user}"
    append "repo" "${repo}"
    append "name" "${name}"
    append "description" "${description}"
    append "docs_url" "${docs_url}"
    append "site_url" "${site_url}"
    append "discord_url" "${discord_url}"

    if [[ -n "${user}" && -n "${repo}" ]]; then

        local repo_url="${github_host}/${user}/${repo}"
        local issues_url="${repo_url}/issues"
        local new_issue_url="${repo_url}/issues/new/choose"
        local discussions_url="${repo_url}/discussions"
        local community_url="${repo_url}/graphs/community"
        local categories_url="${repo_url}/discussions/categories"
        local announcements_url="${repo_url}/discussions/categories/announcements"
        local general_url="${repo_url}/discussions/categories/general"
        local ideas_url="${repo_url}/discussions/categories/ideas"
        local polls_url="${repo_url}/discussions/categories/polls"
        local qa_url="${repo_url}/discussions/categories/q-a"
        local show_and_tell_url="${repo_url}/discussions/categories/show-and-tell"

        append "repo_url" "${repo_url}"
        append "issues_url" "${issues_url}"
        append "new_issue_url" "${new_issue_url}"
        append "discussions_url" "${discussions_url}"
        append "community_url" "${community_url}"
        append "categories_url" "${categories_url}"
        append "announcements_url" "${announcements_url}"
        append "general_url" "${general_url}"
        append "ideas_url" "${ideas_url}"
        append "polls_url" "${polls_url}"
        append "qa_url" "${qa_url}"
        append "show_and_tell_url" "${show_and_tell_url}"
        append "bug_report_url" "${new_issue_url}"
        append "feature_request_url" "${new_issue_url}"

        if [[ -f "${root}/SECURITY.md" ]]; then append "security_url" "$(blob_gh_url "${repo_url}" "${branch}" "SECURITY.md")"
        else append "security_url" "${repo_url}/security"
        fi

        if [[ -f "${root}/.github/SUPPORT.md" ]]; then append "support_url" "$(blob_gh_url "${repo_url}" "${branch}" ".github/SUPPORT.md")"
        elif [[ -f "${root}/SUPPORT.md" ]]; then append "support_url" "$(blob_gh_url "${repo_url}" "${branch}" "SUPPORT.md")"
        else append "support_url" "${discussions_url}"
        fi

        if [[ -f "${root}/CONTRIBUTING.md" ]]; then append "contributing_url" "$(blob_gh_url "${repo_url}" "${branch}" "CONTRIBUTING.md")"
        elif [[ -f "${root}/.github/CONTRIBUTING.md" ]]; then append "contributing_url" "$(blob_gh_url "${repo_url}" "${branch}" ".github/CONTRIBUTING.md")"
        fi

        if [[ -f "${root}/CODE_OF_CONDUCT.md" ]]; then append "code_of_conduct_url" "$(blob_gh_url "${repo_url}" "${branch}" "CODE_OF_CONDUCT.md")"
        elif [[ -f "${root}/.github/CODE_OF_CONDUCT.md" ]]; then append "code_of_conduct_url" "$(blob_gh_url "${repo_url}" "${branch}" ".github/CODE_OF_CONDUCT.md")"
        fi

        [[ -f "${root}/README.md" ]] && append "readme_url" "$(blob_gh_url "${repo_url}" "${branch}" "README.md")"
        [[ -f "${root}/CHANGELOG.md" ]] && append "changelog_url" "$(blob_gh_url "${repo_url}" "${branch}" "CHANGELOG.md")"
        [[ -f "${root}/.github/PULL_REQUEST_TEMPLATE.md" ]] && append "pull_request_template_url" "$(blob_gh_url "${repo_url}" "${branch}" ".github/PULL_REQUEST_TEMPLATE.md")"
        [[ -d "${root}/.github/ISSUE_TEMPLATE" ]] && append "issue_templates_url" "$(tree_gh_url "${repo_url}" "${branch}" ".github/ISSUE_TEMPLATE")"

    fi

    replace_all "${root}" ph_map

}
prepare_git () {

    source <(parse "$@" -- root name repo branch host)

    cd -- "${root}"
    GIT_HOST="${host}" cmd_init "${repo:-${name}}" "${branch}" "${kwargs[@]}"

}

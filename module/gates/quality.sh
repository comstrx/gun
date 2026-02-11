#!/usr/bin/env bash

cmd_typos_check () {

    ensure_pkg typos

    local -a cmd=()

    local config="$(config_file typos toml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run typos --format brief "${cmd[@]}" "$@"

}
cmd_typos_fix () {

    ensure_pkg typos

    local -a cmd=()

    local config="$(config_file typos toml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run typos -w "${cmd[@]}" "$@"

}

cmd_taplo_check () {

    local -a cmd=()

    local config="$(config_file taplo toml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    if has taplo; then
        run taplo fmt --check "${cmd[@]}" "$@"
        return 0
    fi

    ensure_pkg npx
    run npx -y @taplo/cli fmt --check "${cmd[@]}" "$@"

}
cmd_taplo_fix () {

    local -a cmd=()

    local config="$(config_file taplo toml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    if has taplo; then
        run taplo fmt "${cmd[@]}" "$@"
        return 0
    fi

    ensure_pkg npx
    run npx -y @taplo/cli fmt "${cmd[@]}" "$@"

}

cmd_prettier_check () {

    ensure_pkg npx

    local -a cmd=( --check "**/*.{md,mdx,yml,yaml,json,jsonc}" )

    local config="$(config_file prettierrc yaml yml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run npx -y prettier@3.8.1 --no-error-on-unmatched-pattern --ignore-path .gitignore "${cmd[@]}" "$@"

}
cmd_prettier_fix () {

    ensure_pkg npx

    local -a cmd=( --write "**/*.{md,mdx,yml,yaml,json,jsonc}" )

    local config="$(config_file prettierrc yaml yml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run npx -y prettier@3.8.1 --no-error-on-unmatched-pattern --ignore-path .gitignore "${cmd[@]}" "$@"

}

cmd_tree_fix () {

    ensure_pkg git perl
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not a git repo"

    git ls-files -z | perl -e '
        use strict;
        use warnings;
        use File::Basename qw(dirname);
        use File::Temp qw(tempfile);

        binmode(STDIN);
        local $/ = "\0";
        my $ec = 0;

        while (defined(my $path = <STDIN>)) {

            chomp($path);
            next if $path eq "";
            next if -l $path;
            next if !-f $path;
            open my $in, "<:raw", $path or do { $ec = 1; next; };
            local $/;
            my $data = <$in>;
            close $in;
            next if !defined $data;
            next if index($data, "\0") != -1;
            my $changed = ($data =~ s/[ \t]+(?=\r?$)//mg);
            next if !$changed;
            my $dir = dirname($path);
            my ($tmpfh, $tmp) = tempfile(".wsfix.XXXXXX", DIR => $dir, UNLINK => 0) or do { $ec = 1; next; };
            binmode($tmpfh);

            print $tmpfh $data or do { close $tmpfh; unlink($tmp); $ec = 1; next; };
            close $tmpfh or do { unlink($tmp); $ec = 1; next; };
            my @st = stat($path);

            if (@st) {

                chmod($st[2] & 07777, $tmp);
                eval { chown($st[4], $st[5], $tmp); 1; };

            }

            if (rename($tmp, $path)) { next; }
            my $bak = $path . ".wsfix.bak.$$";

            if (!rename($path, $bak)) {

                unlink($tmp);
                $ec = 1;
                next;

            }
            if (!rename($tmp, $path)) {

                rename($bak, $path);
                unlink($tmp);
                $ec = 1;
                next;

            }

            unlink($bak);

        }

        exit($ec);
    '

    run git add --renormalize .
    run git restore .

}

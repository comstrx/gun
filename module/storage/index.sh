#!/usr/bin/env bash

cmd_new_dir () {

    source <(parse "$@" -- :src mode)
    std_new_dir "${src}" "${mode}" "${kwargs[@]}"

}
cmd_new_file () {

    source <(parse "$@" -- :src mode)
    std_new_file "${src}" "${mode}" "${kwargs[@]}"

}
cmd_path_type () {

    source <(parse "$@" -- :src)
    std_path_exists "${src}" && std_path_type "${src}" "${kwargs[@]}"

}
cmd_file_type () {

    source <(parse "$@" -- :src)
    std_file_exists "${src}" && std_file_type "${src}" "${kwargs[@]}"

}
cmd_copy () {

    source <(parse "$@" -- :src :dest)
    std_path_exists "${src}" && std_copy_path "${src}" "${dest}" "${kwargs[@]}"

}
cmd_move () {

    source <(parse "$@" -- :src :dest)
    std_path_exists "${src}" && std_move_path "${src}" "${dest}" "${kwargs[@]}"

}
cmd_remove () {

    source <(parse "$@" -- :src)
    std_path_exists "${src}" && std_remove_path "${src}" "${kwargs[@]}"

}
cmd_trash () {

    source <(parse "$@" -- :src trash_dir)
    std_path_exists "${src}" && std_trash_path "${src}" "${trash_dir}" "${kwargs[@]}"

}
cmd_clear () {

    source <(parse "$@" -- :src)
    std_dir_exists "${src}" && std_remove_path "${src}" true "${kwargs[@]}"
    std_file_exists "${src}" && : > "${src}"

}
cmd_link () {

    source <(parse "$@" -- :src :dest)
    std_path_exists "${src}" && std_link_path "${src}" "${dest}" "${kwargs[@]}"

}
cmd_stats () {

    source <(parse "$@" -- :src)
    std_path_exists "${src}" && std_stats_path "${src}" "${kwargs[@]}"

}
cmd_diff () {

    source <(parse "$@" -- :src :dest)
    std_path_exists "${src}" && std_diff_path "${src}" "${dest}" "${kwargs[@]}"

}
cmd_synced () {

    source <(parse "$@" -- :src :dest)
    std_path_exists "${src}" && std_synced_path "${src}" "${dest}" "${kwargs[@]}"

}
cmd_compress () {

    source <(parse "$@" -- src)
    std_path_exists "${src:-${PWD}}" && std_compress_path "${src}" "${kwargs[@]}"

}
cmd_backup () {

    source <(parse "$@" -- src)
    std_path_exists "${src:-${PWD}}" && std_backup_path "${src}" "${kwargs[@]}"

}
cmd_sync () {

    source <(parse "$@" -- src)
    std_path_exists "${src:-${PWD}}" && std_sync_path "${src}" "${kwargs[@]}"

}

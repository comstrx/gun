#!/usr/bin/env bash

cmd_notify () {

    source <(parse "$@" -- \
        platform:list platforms:list \
        status title message \
        token chat telegram_token telegram_chat \
        webhook url slack_webhook discord_webhook webhook_url \
        retries:int=3 delay:int=1 timeout:float=10 max_time:float=20 retry_max_time:float=60 \
    )

    local msg="${message:-"$(notify_message "${status}" "${title}")"}"

    local -a args=(
        -fsS
        --connect-timeout "${timeout}"
        --max-time "${max_time}"
        --retry-max-time "${retry_max_time}"
        --retry "${retries}"
        --retry-delay "${delay}"
        --retry-connrefused
    )

    local -a plats=() failed=()
    local  p=""

    if (( ${#platform[@]} )); then plats=( "${platform[@]}" )
    elif (( ${#platforms[@]} )); then plats=( "${platforms[@]}" )
    else plats=( telegram )
    fi

    for p in "${plats[@]}"; do

        case "${p,,}" in
            telegram) notify_telegram args "${telegram_token:-${token}}" "${telegram_chat:-${chat}}" "${msg}" || failed+=( telegram ) ;;
            slack)    notify_slack    args "${slack_webhook:-${webhook:-${url:-}}}" "${msg}" || failed+=( slack ) ;;
            discord)  notify_discord  args "${discord_webhook:-${webhook:-${url:-}}}" "${msg}" || failed+=( discord ) ;;
            webhook)  notify_webhook  args "${webhook_url:-${webhook:-${url:-}}}" "${msg}" || failed+=( webhook ) ;;
            *) failed+=( "${p}" ) ;;
        esac

    done

    if (( ${#failed[@]} )); then die "Failed to send ( ${failed[*]} ) notification"
    else success "Ok: Notification sent successfully ( ${plats[*]} )"
    fi

}

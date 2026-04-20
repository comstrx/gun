
__enter__ () {

    __trace__

    local cmd="${1:-}"
    shift || true

    case "${cmd}" in
        --test)  __test__ "$@" ;;
        --tests) __tests__ "$@" ;;
        *)       main "$@" ;;
    esac

}

__enter__ "$@"
exit $?

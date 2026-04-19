#!/usr/bin/env bash
set -Eeuo pipefail
main(){
echo "Hello World"
}
start(){
main "$@"
exit $?
}
start "$@"

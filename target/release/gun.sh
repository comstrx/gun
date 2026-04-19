#!/usr/bin/env bash
set -Eeuo pipefail
main(){
user done
echo "Hello World"
}
start(){
main "$@"
exit $?
}
start "$@"

#!/usr/bin/env bash
set -Eeuo pipefail

BUILTIN_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"

source "${BUILTIN_DIR}/cast.sh"       # Done
source "${BUILTIN_DIR}/dir.sh"        # 
source "${BUILTIN_DIR}/env.sh"        # 
source "${BUILTIN_DIR}/file.sh"       # 
source "${BUILTIN_DIR}/hook.sh"       # 
source "${BUILTIN_DIR}/list.sh"       # 
source "${BUILTIN_DIR}/map.sh"        # 
source "${BUILTIN_DIR}/parse.sh"      # 
source "${BUILTIN_DIR}/path.sh"       # 
source "${BUILTIN_DIR}/process.sh"    # Done
source "${BUILTIN_DIR}/platform.sh"   # Done
source "${BUILTIN_DIR}/stdin.sh"      # 
source "${BUILTIN_DIR}/stdout.sh"     # 
source "${BUILTIN_DIR}/string.sh"     # 
source "${BUILTIN_DIR}/test.sh"       # 
source "${BUILTIN_DIR}/use.sh"        # 

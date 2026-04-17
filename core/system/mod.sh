[[ -n "${CORE_SYSTEM_LOADED:-}" ]] && return 0
readonly CORE_SYSTEM_LOADED=1
readonly CORE_SYSTEM_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"

source "${CORE_SYSTEM_DIR}/base.sh"

source "${CORE_SYSTEM_DIR}/manager.sh"
source "${CORE_SYSTEM_DIR}/process.sh"

source "${CORE_SYSTEM_DIR}/facade.sh"

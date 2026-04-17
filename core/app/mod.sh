[[ -n "${CORE_APP_LOADED:-}" ]] && return 0
readonly CORE_APP_LOADED=1
readonly CORE_APP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"

source "${CORE_APP_DIR}/base.sh"

source "${CORE_APP_DIR}/log.sh"
source "${CORE_APP_DIR}/run.sh"

source "${CORE_APP_DIR}/facade.sh"

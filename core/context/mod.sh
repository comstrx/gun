[[ -n "${CORE_CONTEXT_LOADED:-}" ]] && return 0
readonly CORE_CONTEXT_LOADED=1
readonly CORE_CONTEXT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"

source "${CORE_CONTEXT_DIR}/base.sh"

source "${CORE_CONTEXT_DIR}/hook.sh"
source "${CORE_CONTEXT_DIR}/temp.sh"

source "${CORE_CONTEXT_DIR}/facade.sh"

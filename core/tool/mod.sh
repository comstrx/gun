[[ -n "${CORE_TOOL_LOADED:-}" ]] && return 0
readonly CORE_TOOL_LOADED=1
readonly CORE_TOOL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"

source "${CORE_TOOL_DIR}/base.sh"

source "${CORE_TOOL_DIR}/map.sh"
source "${CORE_TOOL_DIR}/path.sh"
source "${CORE_TOOL_DIR}/process.sh"

source "${CORE_TOOL_DIR}/facade.sh"

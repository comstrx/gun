[[ -n "${CORE_PARSE_LOADED:-}" ]] && return 0
readonly CORE_PARSE_LOADED=1
readonly CORE_PARSE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"

source "${CORE_PARSE_DIR}/base.sh"

source "${CORE_PARSE_DIR}/match.sh"
source "${CORE_PARSE_DIR}/regex.sh"

source "${CORE_PARSE_DIR}/facade.sh"

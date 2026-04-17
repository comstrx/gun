[[ -n "${CORE_LOADED:-}" ]] && return 0
readonly CORE_LOADED=1
readonly CORE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"

source "${CORE_DIR}/app/mod.sh"
source "${CORE_DIR}/context/mod.sh"
source "${CORE_DIR}/system/mod.sh"
source "${CORE_DIR}/network/mod.sh"
source "${CORE_DIR}/parse/mod.sh"
source "${CORE_DIR}/tool/mod.sh"

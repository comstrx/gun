[[ -n "${CORE_NETWORK_LOADED:-}" ]] && return 0
readonly CORE_NETWORK_LOADED=1
readonly CORE_NETWORK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"

source "${CORE_NETWORK_DIR}/base.sh"

source "${CORE_NETWORK_DIR}/http.sh"
source "${CORE_NETWORK_DIR}/socket.sh"

source "${CORE_NETWORK_DIR}/facade.sh"

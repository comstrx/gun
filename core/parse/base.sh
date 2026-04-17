
# ======>> Parser Engine <<======

# ======>> Target
#
# Language : Bash 5+
# Style    : modern, safe, production-grade Bash
# Goal     : build all internal functions with the prefix `parse_`
# Facade   : `parse "$@" -- ...`

# ======>> Rules
#
# :name
#   mark the variable as required (die if missed)
#
# name=value
#   set a default value
#   if a required variable already has a default value, no missing-value error is raised
#
# name:type
#   validate the input using the given type, then assign it (die if not matched type)
#
# name:[type]
#   assign the default value for the given type
# 
#   int      -> 0
#   float    -> 0.0
#   str      -> ""
#   char     -> ""
#   file     -> ""
#   dir      -> ""
#   url      -> ""
#   email    -> ""
#   bool     -> false
#   list     -> -a ()
#   dict     -> -A ()
#   enum     -> first value or ""

# ======>> Behavior
#
# - `parse` receive values with two options (Flags or getopts or Positional) -> --name vlaue or -name value or value
# - `parse` Only the last value is considered, and it makes it modify all previous values ​​of the same variable
# - `parse` creates and assigns all declared variables
# - `parse` receive list e.g -> (--data item1 --data item2 --data item3) or (--data item1 item2 item3)
# - `parse` receive dict e.g -> (--info key1=value1 --info key2=value2 --info key3=value3) or (--info key1=value1 key2=value2 key3=value3)
# - all unparsed arguments are stored in `kwargs`
# - forward extra arguments with: "${kwargs[@]}"
# - try to build parser 100% Pure Bash To ensure maximum speed
# - External tools such as sed, awk, and gerp should only be invoked in extreme necessity and when the Pasch system is unable to function.

# ======>> Example
#
# parse "$@" -- \
#     :name:str \
#     section:char \
#     age:int \
#     salary:float \
#     admin:bool \
#     site:url \
#     email:email \
#     password:any \
#     image_path:file \
#     dir_path:dir="." \
#     created_at:date \
#     updated_at:time \
#     deleted_at:datetime \
#     active:bool=true \
#     data:list \
#     info:dict \
#     role:enum(admin|client|vendor)=client


parse_die() {
    printf "[\e[31mPARSE ERROR\e[0m] %s\n" "$1" >&2
    exit 1
}
parse_validate() {
    local key="$1" type="$2" val="$3"

    # Enum Validation
    if [[ "$type" == enum\(*\)* ]]; then
        local opts="${type#enum(}"
        opts="${opts%)}"
        [[ "|$opts|" == *"|$val|"* ]] || parse_die "Invalid enum for '$key'. Expected: $opts, Got: '$val'"
        return 0
    fi

    local regex=""
    case "$type" in
        int) regex="^[-+]?[0-9]+$" ;;
        float) regex="^[-+]?[0-9]*\.[0-9]+$" ;;
        bool) regex="^(true|false|1|0|yes|no)$" ;;
        email) regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" ;;
        url) regex="^https?://" ;;
        date) regex="^[0-9]{4}-[0-9]{2}-[0-9]{2}$" ;;
        time) regex="^[0-9]{2}:[0-9]{2}(:[0-9]{2})?$" ;;
        datetime) regex="^[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}(:[0-9]{2})?$" ;;
        char) ((${#val} == 1)) || parse_die "'$key' must be a single character." ; return 0 ;;
        file) [[ -f "$val" ]] || parse_die "'$key' file not found: $val" ; return 0 ;;
        dir) [[ -d "$val" ]] || parse_die "'$key' directory not found: $val" ; return 0 ;;
        str|any|list|dict) return 0 ;;
        *) parse_die "Unknown type '$type' for '$key'." ;;
    esac

    if [[ -n "$regex" ]]; then
        [[ "$val" =~ $regex ]] || parse_die "Validation failed for '$key': expected '$type', got '$val'."
    fi
}
parse_assign() {
    local key="$1" type="$2" val="$3"
    
    # Using Namerefs (Bash 4.3+) to safely mutate caller's arrays without `eval`
    if [[ "$type" == "list" ]]; then
        declare -n _list_ref="$key"
        _list_ref+=("$val")
    elif [[ "$type" == "dict" ]]; then
        declare -n _dict_ref="$key"
        local dict_k="${val%%=*}"
        local dict_v="${val#*=}"
        _dict_ref["$dict_k"]="$dict_v"
    else
        _parse_values["$key"]="$val"
    fi
}
parse() {
    local inputs=() schemas=()
    local in_schema=0
    local arg

    # 1. Isolate Inputs and Schemas
    for arg in "$@"; do
        if [[ "$arg" == "--" && $in_schema == 0 ]]; then
            in_schema=1
            continue
        fi
        if (( in_schema )); then
            schemas+=("$arg")
        else
            inputs+=("$arg")
        fi
    done

    # 2. Internal State Tracking
    local -a _parse_ordered_names=()
    local -A _parse_types=()
    local -A _parse_required=()
    local -A _parse_defaults=()
    # Global explicit tracking to differentiate between empty string and unset
    local -A _parse_values=()
    
    # Expose unparsed args to the caller
    declare -ga kwargs=()

    # 3. Compile Schema
    local token req is_auto_type name type has_default default
    for token in "${schemas[@]}"; do
        req=0; is_auto_type=0; has_default=0; default=""
        
        # Required flag
        if [[ "$token" == :* ]]; then req=1; token="${token#:}"; fi
        
        # Name extraction
        name="${token%%[:=]*}"
        token="${token#"$name"}"
        
        # Type extraction
        type="any"
        if [[ "$token" == :* ]]; then
            token="${token#:}"
            type="${token%%=*}"
            token="${token#"$type"}"
        fi
        
        # Auto-type fallback flag (e.g. :[int])
        if [[ "$type" == \[*\] ]]; then
            is_auto_type=1
            type="${type#\[}"
            type="${type%\]}"
        fi
        
        # Default value extraction
        if [[ "$token" == =* ]]; then
            has_default=1
            default="${token#=}"
        elif (( is_auto_type == 1 )); then
            has_default=1
            case "$type" in
                int) default="0" ;;
                float) default="0.0" ;;
                bool) default="false" ;;
                str|char|file|dir|url|email|any) default="" ;;
                enum\(*\)*)
                    local opts="${type#enum(}"
                    opts="${opts%)}"
                    default="${opts%%|*}"
                    ;;
            esac
        fi
        
        _parse_ordered_names+=("$name")
        _parse_types["$name"]="$type"
        _parse_required["$name"]=$req
        (( has_default == 1 )) && _parse_defaults["$name"]="$default"
        
        # Pre-declare target globals to ensure Namerefs work safely
        if [[ "$type" == "list" ]]; then
            declare -ga "$name=()"
        elif [[ "$type" == "dict" ]]; then
            declare -gA "$name=()"
        else
            declare -g "$name="
        fi
    done

    # 4. Parse Inputs via State Machine
    local current_key="" current_type="" pos_idx=0 i clean_key inline_val
    for (( i=0; i < ${#inputs[@]}; i++ )); do
        arg="${inputs[i]}"
        
        # Match Flag (-flag or --flag)
        if [[ "$arg" == -* ]]; then
            clean_key="${arg#-}"
            clean_key="${clean_key#-}"
            inline_val=""
            
            # Extract inline assignments (--key=value)
            if [[ "$clean_key" == *=* ]]; then
                inline_val="${clean_key#*=}"
                clean_key="${clean_key%%=*}"
            fi
            
            # Known Flag Processing
            if [[ -v _parse_types["$clean_key"] ]]; then
                current_key="$clean_key"
                current_type="${_parse_types["$current_key"]}"
                
                if [[ -n "$inline_val" ]]; then
                    parse_assign "$current_key" "$current_type" "$inline_val"
                    [[ "$current_type" != "list" && "$current_type" != "dict" ]] && current_key=""
                elif [[ "$current_type" == "bool" ]]; then
                    parse_assign "$current_key" "bool" "true"
                    current_key="" # Bools act as flags, do not consume next pos-arg
                fi
                continue
            else
                # Unknown Flag
                kwargs+=("$arg")
                current_key=""
                continue
            fi
        fi
        
        # Match Positional or Continued Values (Lists/Dicts)
        if [[ -n "$current_key" ]]; then
            parse_assign "$current_key" "$current_type" "$arg"
            [[ "$current_type" != "list" && "$current_type" != "dict" ]] && current_key=""
        else
            # Native Positional Mapping
            if (( pos_idx < ${#_parse_ordered_names[@]} )); then
                local p_key="${_parse_ordered_names[pos_idx]}"
                local p_type="${_parse_types["$p_key"]}"
                parse_assign "$p_key" "$p_type" "$arg"
                if [[ "$p_type" == "list" || "$p_type" == "dict" ]]; then
                    current_key="$p_key"
                    current_type="$p_type"
                fi
                ((pos_idx++))
            else
                kwargs+=("$arg")
            fi
        fi
    done

    # 5. Defaults Application & Validation
    local key type req val size
    for key in "${_parse_ordered_names[@]}"; do
        type="${_parse_types["$key"]}"
        req="${_parse_required["$key"]}"
        
        if [[ "$type" != "list" && "$type" != "dict" ]]; then
            val="${_parse_values["$key"]:-}"
            
            # If completely unset (not even passed as empty string)
            if [[ ! -v _parse_values["$key"] ]]; then
                if [[ -v _parse_defaults["$key"] ]]; then
                    val="${_parse_defaults["$key"]}"
                elif (( req == 1 )); then
                    parse_die "Missing required argument: --$key"
                fi
            fi
            
            # Validate if value exists or is strictly required
            if [[ -n "$val" || (( req == 1 )) ]]; then
                parse_validate "$key" "$type" "$val"
            fi
            
            # Export to Caller's Scope
            declare -g "$key=$val"
        else
            # Collections validation
            if [[ "$type" == "list" ]]; then
                declare -n _ref_list="$key"
                size=${#_ref_list[@]}
            else
                declare -n _ref_dict="$key"
                size=${#_ref_dict[@]}
            fi
            
            if (( size == 0 && req == 1 )); then
                parse_die "Missing required argument: --$key"
            fi
        fi
    done
}

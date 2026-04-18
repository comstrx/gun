
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

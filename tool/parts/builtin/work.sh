
while IFS= read -r -d '' file; do
    shellcheck "${file}" -e SC2148 -e SC1090 -e SC2034 -e SC2178 || exit 1
done < <(find ./tool/builtin -type f -name '*.sh' ! -name arch.sh ! -name work.sh -print0)

#### Description #################################################################################
#
# Merges the content of all .json files in the repository containing cipher queries into a single
# BloodHound-formated file.
#
####

repo_root_dir="$(realpath $0 | sed 's/\.github.*//')"
output_file="${repo_root_dir}customqueries.json"
files_to_merge="$(find "$repo_root_dir" -regextype posix-extended -regex '.*[0-9]{2}.*\.json' | sort)"
merged_file='merged.json'

for file in ${files_to_merge[@]}
do
    cat "$file" >> "$merged_file"
done

printf '{ "queries": %s }' "$(jq --slurp . $merged_file)" | jq -r > "$output_file"
rm -rf "$merged_file"
echo "Queries merged to: $output_file"

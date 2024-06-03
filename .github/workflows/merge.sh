#### Description #################################################################################
#
# Merges the content of all .json files in the repository containing cipher queries into a single
# BloodHound-formated file.
#
####

##
# Merge content into a temporary file
##
repo_root_dir="$(realpath $0 | sed 's/\.github.*//')"
output_file="${repo_root_dir}customqueries.json"
files_to_merge="$(find "$repo_root_dir" -regextype posix-extended -regex '.*[0-9]{2}.*\.json' | sort)"
merged_file='merged.json'

for file in ${files_to_merge[@]}
do
    cat "$file" >> "$merged_file"
done

##
# Match and replace placeholders with content
##
placeholder_azure_roles_tier_0='$VAR_ALL-AZ-ROLES-IN-T0'
placeholder_entra_roles_tier_0='$VAR_ALL-ENTRA-ROLES-IN-T0'
placeholder_entra_app_permissions_tier_0='$VAR_ALL-ENTRA-APP-PERMISSIONS-IN-T0'
placeholder_azure_resources='$VAR_ALL-AZ-RESOURCES'

tiering_dir="${repo_root_dir}/tiering/"
tier_file_azure_roles="${tiering_dir}azure-roles.json"
tier_file_entra_roles="${tiering_dir}entra-roles.json"
tier_file_entra_app_permissions="${tiering_dir}entra-application-permissions.json"

azure_roles_tier_0="$(cat $tier_file_azure_roles | jq -r '.[] | select(.tier == "0" and .edgeName != "") | .edgeName' | sed -n ':a;N;${s/\n/|/g;p};ba')"
entra_roles_tier_0="$(cat $tier_file_entra_roles | jq -r '.[] | select(.tier == "0" and .edgeName != "") | .edgeName' | sed -n ':a;N;${s/\n/|/g;p};ba')"
entra_app_permissions_tier_0="$(cat $tier_file_entra_app_permissions | jq -r '.[] | select(.tier == "0" and .edgeName != "") | .edgeName' | sed -n ':a;N;${s/\n/|/g;p};ba')"

echo $merged_file \
| sed "s/${placeholder_azure_roles_tier_0}/${azure_roles_tier_0}/" \
| sed "s/${placeholder_entra_roles_tier_0}/${entra_roles_tier_0}/" \
| sed "s/${placeholder_entra_app_permissions_tier_0}/${entra_app_permissions_tier_0}/" \
> $merged_file

##
# Export results to the output file
##
printf '{ "queries": %s }' "$(jq --slurp . $merged_file)" | jq -r > "$output_file"
rm -rf "$merged_file"
echo "Queries merged to: $output_file"

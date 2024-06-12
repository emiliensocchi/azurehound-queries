#### Description #################################################################################
#
# Merges the content of all .json files in the repository containing cipher queries into a single
# BloodHound-formated file, and replaces custom BloodHound variables with specific content.
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

#-- Tiering

# Tiering placeholders
placeholder_entra_roles_tier_0='_VAR_all-entra-roles-in-t0'
placeholder_entra_app_permissions_tier_0='_VAR_all-entra-app-permissions-in-t0'
placeholder_entra_app_permissions_tier_1='_VAR_all-entra-app-permissions-in-t1'
placeholder_azure_roles_tier_0='_VAR_all-az-roles-in-t0'

# Tiering files
tiering_dir="${repo_root_dir}/variables/"
tier_file_entra_roles="${tiering_dir}tiering-entra-roles.json"
tier_file_entra_app_permissions="${tiering_dir}tiering-entra-application-permissions.json" 
tier_file_azure_roles="${tiering_dir}tiering-azure-roles.json"

# Tiering content
entra_roles_tier_0="$(cat $tier_file_entra_roles | jq -r '.[] | select(.tier == "0" and .edgeName != "") | .edgeName' | sed -n ':a;N;${s/\n/|/g;p};ba')"
entra_app_permissions_tier_0="$(cat $tier_file_entra_app_permissions | jq -r '.[] | select(.tier == "0" and .edgeName != "") | .edgeName' | sed -n ':a;N;${s/\n/|/g;p};ba')"
entra_app_permissions_tier_1="$(cat $tier_file_entra_app_permissions | jq -r '.[] | select(.tier == "1" and .edgeName != "") | .edgeName' | sed -n ':a;N;${s/\n/|/g;p};ba')"
azure_roles_tier_0="$(cat $tier_file_azure_roles | jq -r '.[] | select(.tier == "0" and .edgeName != "") | .edgeName' | sed -n ':a;N;${s/\n/|/g;p};ba')"


#-- Helpers

# Helper placeholders
placeholder_built_in_service_principals='_VAR_built-in-service-principals'
placeholder_all_security_principals='_VAR_all-security-principals'
placeholder_all_security_principals_excluding_built_in='_VAR_all-security-principals-excluding-built-in'
placeholder_service_principals_excluding_built_in='_VAR_service-principals-excluding-built-in'
placeholder_managed_identities_excluding_built_in='_VAR_managed-identities-excluding-built-in'
placeholder_all_azure_resources='_VAR_all-az-resources'
placeholder_high_level_azure_scopes='_VAR_high-level-az-scopes'
placeholder_all_azure_scopes='_VAR_all-az-scopes'

# Helper file
helper_dir="${repo_root_dir}/variables/"
helper_file="${helper_dir}helpers.json"

# Helper content
helper_built_in_service_principals="$(cat $helper_file | jq '.[] | select(.variableName == '\"$placeholder_built_in_service_principals\"') | .components[]' | sed "s/\"/'/g" | sed -n ':a;N;${s/\n/ or node.displayname starts with /g;p};ba')"
helper_all_security_principals="$(cat $helper_file | jq -r '.[] | select(.variableName == '\"$placeholder_all_security_principals\"') | .components[]' | sed -n ':a;N;${s/\n/ or node:/g;p};ba')"
helper_all_security_principals_excluding_built_in="$(echo $helper_all_security_principals | sed "s/ node:AZServicePrincipal/ \(node:AZServicePrincipal AND NOT \(node.displayname STARTS WITH $helper_built_in_service_principals\)\)/")"
helper_service_principals_excluding_built_in=":AZServicePrincipal {serviceprincipaltype: 'Application'} AND NOT (node.displayname STARTS WITH $helper_built_in_service_principals)"
helper_service_managed_identities_excluding_built_in=":AZServicePrincipal {serviceprincipaltype: 'ManagedIdentity'} AND NOT (node.displayname STARTS WITH $helper_built_in_service_principals)"
helper_all_azure_resources="$(cat $helper_file | jq -r '.[] | select(.variableName == '\"$placeholder_all_azure_resources\"') | .components[]' | sed -n ':a;N;${s/\n/ or node:/g;p};ba')"
helper_high_level_azure_scopes="$(cat $helper_file | jq -r '.[] | select(.variableName == '\"$placeholder_high_level_azure_scopes\"') | .components[]' | sed -n ':a;N;${s/\n/ or node:/g;p};ba')"
helper_all_scopes="$(echo ${helper_high_level_azure_scopes} or node:${helper_all_azure_resources})"


#-- Replace and merge content

cat $merged_file \
| sed "s/${placeholder_entra_roles_tier_0}/${entra_roles_tier_0}/" \
| sed "s/${placeholder_entra_app_permissions_tier_0}/${entra_app_permissions_tier_0}/" \
| sed "s/${placeholder_entra_app_permissions_tier_1}/${entra_app_permissions_tier_1}/" \
| sed "s/${placeholder_azure_roles_tier_0}/${azure_roles_tier_0}/" \
| sed "s/${placeholder_all_security_principals_excluding_built_in}/${helper_all_security_principals_excluding_built_in}/" \
| sed "s/${placeholder_service_principals_excluding_built_in}/${helper_service_principals_excluding_built_in}/" \
| sed "s/${placeholder_managed_identities_excluding_built_in}/${helper_service_managed_identities_excluding_built_in}/" \
| sed "s/${placeholder_all_security_principals}/${helper_all_security_principals}/" \
| sed "s/${placeholder_all_azure_resources}/${helper_all_azure_resources}/" \
| sed "s/${placeholder_high_level_azure_scopes}/${helper_high_level_azure_scopes}/" \
| sed "s/${placeholder_all_azure_scopes}/${helper_all_scopes}/" \
> $merged_file


##
# Export results to the output file
##

printf '{ "queries": %s }' "$(jq --slurp . $merged_file)" | jq -r > "$output_file"
rm -rf "$merged_file"
echo "Queries merged to: $output_file"

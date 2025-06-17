#!/bin/bash

CURRENT_PROFILE=$(yc config profile list | awk '/ACTIVE/ {print $1}')
ANSIBLE_SA_PROFILE="ansible-sa"

cleanup() {
  if [[ -n "$CURRENT_PROFILE" ]]; then
    yc config profile activate "$CURRENT_PROFILE" > /dev/null 2>&1
  fi
}

trap cleanup EXIT

yc config profile activate "$ANSIBLE_SA_PROFILE" > /dev/null 2>&1

generate_list() {
  
  vms_json=$(yc compute instance list --format json)

  hostvars_json=$(echo "$vms_json" | jq -c '.[] | select(.status == "RUNNING")' | while read vm; do
    vm_name=$(echo "$vm" | jq -r '.name')
    ansible_host=$(echo "$vm" | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address')

    jq -n --arg name "$vm_name" \
          --arg host "$ansible_host" \
          --arg user "kirill-gruzdy" \
          --arg key_file "/Users/kirill-gruzdy/.ssh/ansible-server-1/id_rsa" \
          '{
            ($name): {
              "ansible_host": $host,
              "ansible_user": $user,
              "ansible_ssh_private_key_file": $key_file,
              "ansible_ssh_common_args": "-o StrictHostKeyChecking=no"
            }
          }'
  done | jq -s add)
  
  groups_json=$(echo "$vms_json" | jq '{
        "all": {
          "children": [ "ungrouped", "tag_wordpress" ]
        },
        "tag_wordpress": {
          "hosts": [ ( .[] | select(.status == "RUNNING" and .labels.tags == "wordpress") | .name ) ]
        },
        "ungrouped": {
            "hosts": [ ( .[] | select(.status == "RUNNING" and (.labels.tags != "wordpress" or .labels.tags == null)) | .name ) ]
        }
      }')

  jq -n --argjson hostvars "$hostvars_json" \
        --argjson groups "$groups_json" \
        '{ "_meta": { "hostvars": $hostvars } } + $groups'
}

if [[ "$1" == "--list" ]]; then
  generate_list
elif [[ "$1" == "--host" ]]; then
  echo '{}'
else
  echo "Usage: $0 --list or $0 --host <hostname>"
  exit 1
fi

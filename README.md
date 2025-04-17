# BashGPOAbuse
Convenient shell script wrappers around bloodyAD, pyGPOAbuse, and impacket-dacledit to make DACL misconfigurations on GPOs slightly easier to exploit

### Components:
* [gplink.sh](gplink.sh) — uses bloodyAD to streamline the process of linking and immediately enabling GPOs from a Linux machine (it's incredibly difficult otherwise) by writing to LDAP directly
* [localadmin.sh](localadmin.sh) — abuses GPOs to make your compromised user the local admin either on every machine in an OU or, if the `--site` parameter is applied, on every machine throughout the domain including all domain controllers
* [revshell.sh](revshell.sh) — abuses GPOs to spawn a reverse shell with NT AUTHORITY\SYSTEM privileges
* More to come
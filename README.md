# delete privileged domain admins profiles
Remove privileged users profiles with domain admin rights from user folders on any domain client computers. This is by far the best method to prevent "pass the hash" attacks. 
If those high privileged user accounts are always removed from, mimikatz will not work. 
It's always nessecary to implement a privilege access management (PAM) model within your IT infrastructure. This script can also help doing the clean-up after implementation of PAM.

The script can be deployed as group policy, run as scheduled task or manual by a helpdesk agent on windows 7 and higher client computers. 

![image](https://github.com/abydongroup/delete_domain_admins/assets/5834602/9dbd65a1-25c5-4fce-9821-2fd63a64caee)

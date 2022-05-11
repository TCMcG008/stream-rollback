# stream-rollback
Rollback from CentOS Stream

project to assist Linux Administrators / Users who have gone just a bit too far and updated their CentOS deployment to CentOS Stream.  

This script aims to:
  1.  safely roll-back from CentOS Stream to the latest stable version of CentOS Linux (8.5.2111 as of this writing).
  2.  [optional] download the latest migration package of RHEL-based alternatives <br />
		(currently AlmaLinux, Rocky Linux, or official RHEL)

Updated to include option to down-load RHEL-clone deployment script.  

Thanks goes out to Matt Griswold (grizz here at github) for creating the foundation upon which this project is built. <br />
    < https://gist.github.com/grizz/e3668652c0f0b121118ce37d29b06dbf >


USE:
1.  take a snap shot || back-up of the CentOS Stream environment
2.  dowload the script
3.  chmod +x stream-rollback.sh
4.  as root-level user, execute the script
        ./stream-rollback.sh [options]
6.  reboot the system
5.  if successfully rolled-back, manually execute the deployment script of the RHEL clone

 Please NOTE: this software comes free-of-charge with absolutely no warranty whatsoever.
When in doubt, back it up!

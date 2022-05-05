# stream-rollback
Rollback from CentOS Stream

project to assist Linux Administrators / Users who have gone just a bit too far and updated their CentOS deployment to CentOS Stream.  

This script aims to:
  1.  safely roll-back from CentOS Stream to the latest stable version of CentOS Linux (8.5.2111 as of this writing).
  2.  download the latest AlmaLinux-deploy.sh script

Updated to include option to down-load RHEL-clone deployment script.  

Thanks goes out to Matt Griswold (grizz here at github) for creating the foundation upon which this project is built. 
    < https://gist.github.com/grizz/e3668652c0f0b121118ce37d29b06dbf >


USE:
1.  take a snap shot || back-up of the CentOS Stream environment
2.  dowload the script
3.  chmod +x stream-rollback.sh
4.  as root-level user, execute the script: <br />
        ./stream-rollback.sh [options]
5.  reboot the system
6.  if successfully rolled-back, manually execute the deployment script of the RHEL clone


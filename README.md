# stream-rollback
Rollback from CentOS Stream

project to assist Linux Administrators / Users who have gone just a bit too far and updated their CentOS deployment to CentOS Stream.  

This script aims to:
  1.  safely roll-back from CentOS Stream to the latest stable version of CentOS Linux (8.5.2111 as of this writing).
  2.  download the latest AlmaLinux-deploy.sh script

In future versions, options will be enabled to choose which trailing RHEL-clone deployment script to download.  

Thanks goes out to Matt Griswold (grizz here at github) for creating the foundation upon which this project is built.
< https://gist.github.com/grizz/e3668652c0f0b121118ce37d29b06dbf >


USE:
1.  take a snap shot || back-up of the CentOS Stream environment
2.  dowload the script
3.  chmod +x stream-rollback.sh
4.  as root-level user, execute the script
      # ./stream-rollback.sh
6.  reboot the system
5.  if the system is successfully rolled-back, manually execute the script to deploy the trailing || stable RHEL version (hard-coded as AlmaLinux-deploy.sh v. 0.1.12 as of this writing)


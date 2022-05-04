#!/bin/bash

###############################################################################
#                                                                             #
#   stream-rollback.sh          version: 2022-04-20A                          #
#   created by TCMcG008                                                       #
#                                                                             #
#   based on stream2alma.sh     version: 2022-03-27                           #
#   by Matt Griswold                                                          #
#   on GitHub as grizz:                                                       #
#   https://gist.github.com/grizz/e3668652c0f0b121118ce37d29b06dbf            #
#                                                                             #
#   stream-rollback.sh                                                        #
#     script to:                                                              #
#       1. roll CentOS Stream back to CentOS 8.5                              #
#       2. fix EDD 'bugs' in grub.cfg                                         #
#                                                                             #
#   references:                                                               #
#     https://www.linuxquestions.org/questions/linux-virtualization-and-cloud-90/probing-edd-edd-off-to-disable-ok-4175607672/
#     https://forums.centos.org/viewtopic.php?t=71648                         #
#                                                                             #
###############################################################################

PROGNAME=$(basename $0)

# test if user is root:
if [[ $UID != 0 ]]; then
	echo "You must be logged is as the root user to use this script. "
	echo "If you do not have the credentials to become the root user, contact a Domain or Systems Administrator."
	echo "Exiting..."
	exit 1
fi

# define usage:
usage () {
	cat <<- EOF
	Usage 1: $PROGNAME

	RUNNING:
	intended for deployment of Canvas-LMS on Red Hat Enterprise v 8.x x86_64;
	user needs to have:
		1. root / wheel level access on the local systems
		2. a snapshot of the system to be update
		3. luck

 	$PROGNAME	script to convert a CentOS Stream environment to a stable Alma machine
 
	$PROGNAME
		-h | --help		prints this menu

	reference materials for this script:
	https://gist.github.com/grizz/e3668652c0f0b121118ce37d29b06dbf
	https://forums.centos.org/viewtopic.php?t=71648
	https://www.linuxquestions.org/questions/linux-virtualization-and-cloud-90/probing-edd-edd-off-to-disable-ok-4175607672/
		
EOF
 	return
}

if [[ $# > 0 ]]; then
	usage >&2
	exit 3
fi

if [[ ! `which wget` ]]; then
	yum -y install wget
fi

cd ~/bin
wget https://raw.githubusercontent.com/AlmaLinux/almalinux-deploy/master/almalinux-deploy.sh
# NOTE: add choice before d/l?
chmod +x *
cd -

RepoDIR=/etc/yum.repos.d
cd $RepoDIR
REPOS=`ls $RepoDIR | egrep '^CentOS-' | sed -e 's/^.*-//g' -e 's/\.repo$//g'`
# REPOS='BaseOS AppStream ContinuousRelease Devel Extras FastTrack HighAvailability Plus PowerTools'
echo $REPOS


# if CentOS-Linux repos do not exist, create symbolic links:
for REPO in $REPOS; do
	repo=`echo $REPO | tr [:upper:] [:lower:]`
	# customize for non-matching repo-names:
	if [[ $REPO == "HighAvailability" ]]; then
		repo=ha
	fi
	if [[ $REPO == "ContinuousRelease" ]]; then
		repo=cr
	fi
	if [[ ! -e ${RepoDIR}/CentOS-Linux-${REPO}.repo ]]; then
		echo "No -Linux- repo for $repo : creating link..."
		ln -s ${RepoDIR}/CentOS-Stream-${REPO}.repo ${RepoDIR}/CentOS-Linux-${REPO}.repo
		target=${RepoDIR}/CentOS-Linux-${REPO}.repo
		echo "the target is $target"
	# update to centos-vault repos; choose preferred:
		# sed -i -e 's/mirrorlist=http/#mirrorlist=http/g' -e "/^\[$repo\]/a baseurl=https://mirror.rackspace.com/centos-vault/8.5.2111/$REPO/\$basearch/os" $target
		sed -i -e 's/mirrorlist=http/#mirrorlist=http/g' -e "/^\[$repo\]/a baseurl=https://vault.centos.org/8.5.2111/$REPO/\$basearch/os" $target		

	# NOTE: Extras package does not work out of the box due to upper-case; here's the fix:
		if [[ $REPO == Extras ]]; then
			sed -i -e "s/\/$REPO\//\/$repo\//" $target
		fi
	fi
done

	# Above edited from these samples:
	# sed -i -e 's/mirrorlist=http/#mirrorlist=http/g' -e '/^\[baseos\]/a baseurl=https://mirror.rackspace.com/centos-vault/8.5.2111/BaseOS/$basearch/os' /etc/yum.repos.d/CentOS-Linux-BaseOS.repo 
	#sed -i -e 's/mirrorlist=http/#mirrorlist=http/g' -e '/^\[baseos\]/a baseurl=https://mirror.rackspace.com/centos-vault/8.5.2111/BaseOS/$basearch/os' /etc/yum.repos.d/CentOS-Linux-BaseOS.repo 

	# PLEASE NOTE: certain repositories, like ContinuousRelease or HighAvailability may not work with the above due to differing names:
	# sed -i -e 's/mirrorlist=http/#mirrorlist=http/g' -e '/^\[cr\]/a baseurl=https://mirror.rackspace.com/centos-vault/8.5.2111/ContinuousRelease/$basearch/os' /etc/yum.repos.d/CentOS-Linux-ContinuousRelease.repo
	# in the above for loop is an example of how to work around this.


# remove packages not in base RHEL
yum remove -y glibc-gconv-extra NetworkManager-initscripts-updown

# switch release versions:
dnf swap centos-{stream,linux}-release --nobest --assumeyes
rValDNF=$?
echo "the rValDNF value is $rValDNF ."

# sync to new repo files and reboot
dnf distro-sync -y

# delete Stream release packages; remove old Stream repos:
rpm -e --nodeps centos-stream-release
if [[ $rValDNF == 0 ]]; then
	rm -f ${RepoDIR}/CentOS-Stream-*
else
	echo "The swap from Stream encountered errors. "
fi

yum -y install centos-linux-release --releasever=8 centos-linux-repos --allowerasing

systemctl daemon-reload

# fix ttyS0 bug, generate a new grub2.cfg file:
if [[ `grep 'console=ttyS0' /etc/default/grub` && ! `grep 'console=tty0' /etc/default/grub` ]]; then
	sed -i -e 's/console=/console=tty0 console=/g' /etc/default/grub
fi
/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg

if [[ `grep 'CentOS Linux' /etc/redhat-release` ]]; then
	echo "The system has been successfully rolled back to `cat /etc/redhat-release`."
	echo -e "$HOSTNAME will now reboot.  \b
	After the system comes back up, log back in and confirm it is stable.  \b
	If it is, create a system snapshot of that stable state before proceeding to \b
	subsequently run any migration scripts manually.  \b
	Best of luck!"
	reboot
else
	echo "It seems the system did not revert as designed.  \b
	Review the above output for more information and adjust this script accordingly. "
fi


# continue on with https://github.com/AlmaLinux/almalinux-deploy
# almalinux-deploy.sh



exit 0

#!/bin/bash

###############################################################################
#                                                                             #
#   stream-rollback.sh          version: 2022-05-10A                          #
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
#       3. [optional] download a RHEL-clone installation script               #
#                                                                             #
#   references:                                                               #
#     https://www.linuxquestions.org/questions/linux-virtualization-and-cloud-90/probing-edd-edd-off-to-disable-ok-4175607672/
#     https://forums.centos.org/viewtopic.php?t=71648                         #
#     https://computingforgeeks.com/how-to-convert-centos-8-to-rhel-8-server/ #
#                                                                             #
###############################################################################

PROGNAME=$(basename $0)

# define usage:
usage () {
	cat <<- EOF
	Usage 1: $PROGNAME

	RUNNING:
	intended for roll-back of a CentOS 8 Stream system to the STABLE 8.5 release;
	user needs to have:
		1. root / wheel level access on the local systems
		2. a snapshot of the system to be update
		3. luck

 	$PROGNAME	script to convert a CentOS Stream environment to a stable Alma machine

	$PROGNAME [ -h | --help | -R | --rocky | -A | --alma ]
		-h | --help     prints this menu
		-R | --rocky    downloads the current Rocky Linux deployment script
		-A | --alma     downloads the current AlmaLinux deployment script
		-RH| --redhat	downloads the current version of Convert2RHEL script

	NOTE: the script will only d/l the choice; it will not install it.  This must \
	be done manually, after reboot.

	reference materials for this script:
	https://gist.github.com/grizz/e3668652c0f0b121118ce37d29b06dbf
	https://forums.centos.org/viewtopic.php?t=71648
	https://www.linuxquestions.org/questions/linux-virtualization-and-cloud-90/probing-edd-edd-off-to-disable-ok-4175607672/
	https://computingforgeeks.com/how-to-convert-centos-8-to-rhel-8-server/

EOF
 	return
}

# test if user is root:
if [[ $UID != 0 ]]; then
	echo "You must be logged is as the root user to use this script. "
	echo "If you do not have the credentials to become the root user, contact a Domain or Systems Administrator."
	echo "Exiting..."
	exit 1
fi

if [[ $# > 0 ]]; then
	case "${1}" in
		-h|--help)	usage >&2
				exit 3
				;;
		-R|--rocky)	RHEL_Clone='Rocky Linux'
				RURL_Clone='https://raw.githubusercontent.com/rocky-linux/rocky-tools/main/migrate2rocky/migrate2rocky.sh'
				;;
		-A|--alma)	RHEL_Clone='AlmaLinux'
				RURL_Clone='https://raw.githubusercontent.com/AlmaLinux/almalinux-deploy/master/almalinux-deploy.sh'
				;;
		-RH|--redhat)	RHEL_Clone='Red Hat Enterprise Linux'
				RHEL_Release=`egrep ^VERSION_ID /etc/os-release | sed -e 's/^.*="//' -e 's/".*$//' | sed -e 's/\..*$//'`
				RURL_Clone="https://ftp.redhat.com/redhat/convert2rhel/${RHEL_Release}/convert2rhel.repo"
				;;
		*)		echo "Not a valid option; exiting... "
				usage >&2
				exit 3
				;;
	esac
fi

if [[ $RHEL_Clone ]]; then
	if [[ ! `which wget` ]]; then
		yum -y install wget
	fi

	cd ~/bin
	echo "Downloading the deployment script for $RHEL_Clone ..."
	if [[ $RHEL_Clone == 'Red Hat Enterprise Linux' ]]; then
		curl -o /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release -k https://www.redhat.com/security/data/fd431d51.txt
		curl --create-dirs -o /etc/rhsm/ca/redhat-uep.pem -k https://ftp.redhat.com/redhat/convert2rhel/redhat-uep.pem
		curl -o /etc/yum.repos.d/convert2rhel.repo -k $RURL_Clone # https://ftp.redhat.com/redhat/convert2rhel/8/convert2rhel.repo
		yum -y install convert2rhel
	else
		wget $RURL_Clone
		chmod +x `basename ${RURL_Clone}`
	fi
	cd -
else
	echo "No RHEL Clone chosen.  Proceeding ..."
fi

RepoDIR=/etc/yum.repos.d
cd $RepoDIR
REPOS=`ls $RepoDIR | egrep '^CentOS-' | sed -e 's/^.*-//g' -e 's/\.repo$//g'`
echo $REPOS


# if CentOS-Linux repos do not exist, create symbolic links:
for REPO in $REPOS; do
	repo=`echo $REPO | tr [:upper:] [:lower:]`

	# PLEASE NOTE: certain repositories, like ContinuousRelease or HighAvailability may not work with the scripting due to differing names;
	# this "hack" customizes for non-matching repo-names; edit / copy as needed:
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

	# Above edited from this samples:
	# sed -i -e 's/mirrorlist=http/#mirrorlist=http/g' -e '/^\[baseos\]/a baseurl=https://mirror.rackspace.com/centos-vault/8.5.2111/BaseOS/$basearch/os' /etc/yum.repos.d/CentOS-Linux-BaseOS.repo 

	# NOTE: Extras package does not work out of the box due to upper-case; here's the hack/fix:
		if [[ $REPO == Extras ]]; then
			sed -i -e "s/\/$REPO\//\/$repo\//" $target
		fi
	fi
done


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
	if [[ $RHEL_Clone == 'Red Hat Enterprise Linux' ]]; then
		echo -e "You have chosen $RHEL_Clone for your migration target. \n
		Please note that license keys from Red Hat will be needed to fully activate your \n
		RHEL system.  More information about Red Hat licenses can be found here: \n
		  https://www.redhat.com/en/resources/red-hat-enterprise-linux-subscription-guide"
	fi
	echo -e "$HOSTNAME will now reboot.  
	After the system comes back up, log back in and confirm it is stable.  \n
	If it is, create a system snapshot of that stable state before proceeding to \n
	subsequently run any migration scripts manually.  \n
	Best of luck!"
	reboot
else
	echo -e "It seems the system did not revert as designed.  \n
	Review the above output for more information and adjust this script accordingly. "
fi


exit 0

#!/bin/bash

#
# This script will prepare a clean arch chroot directory
# for build purposes. This differs from arch's devtools
# by not requiring any build packages on the host machine.
# It's also signifcantly less capable, dirtier, and primarily
# hardcoded to work just for me.
#

TMPDIR=/tmp/chroot


checkroot() {
	if [[ $EUID != 0 ]]; then {
		echo "This script should be ran as root"
		exit -1
	}
	fi
}

prepchroot() {
	echo "builduser:x:1000:1000:builduser:/build:/bin/bash" >> "$TMPDIR/etc/passwd"
	echo "builduser:x:1000:" >> "$TMPDIR/etc/group"
	cp /etc/locale.gen "$TMPDIR/etc/locale.gen"
	cp /etc/locale.conf "$TMPDIR/etc/locale.conf"
	cp /etc/resolv.conf "$TMPDIR/etc/resolv.conf"
	chroot "$TMPDIR" locale-gen
}

create() {
	mkdir -p "$TMPDIR/var/lib/pacman"
	pacman -r "$TMPDIR" -Sy base-devel
	mount proc "$TMPDIR/proc" -t proc -o nosuid,noexec,nodev
	mount sys "$TMPDIR/sys" -t sysfs -o nosuid,noexec,nodev,ro
	mount udev "$TMPDIR/dev" -t devtmpfs -o mode=0755,nosuid
	mount devpts "$TMPDIR/dev/pts" -t devpts -o mode=0620,gid=5,nosuid,noexec

	mkdir "$TMPDIR/build"
	chown 1000:1000 "$TMPDIR/build"
	cp ~/.makepkg.conf "$TMPDIR/build/.makepkg.conf"

	prepchroot

	echo "Build chroot prepared"
	echo "Invoke 'pacman -r $TMPDIR --cachedir $TMPDIR/var/cache/pacman/pkg'"
	echo "  to install additional dependancies into the chroot"
	echo ""
	echo "Invoke 'sudo -u builduser makepkg' while chrooted to run makepkg"
	echo ""
	echo "To remove chroot, launch script with clean action"
}

clean() {
	umount "$TMPDIR/dev/pts"
	umount "$TMPDIR/dev"
	umount "$TMPDIR/sys"
	umount "$TMPDIR/proc"
}

usage() {
	echo "Usage: $0 create|clean"
	echo ""
	echo "create: creates a build chroot"
	echo "clean: cleans the system mounts for a build chroot"
}

case $1 in
create)
	checkroot
	create
	;;
clean)
	checkroot
	clean
	;;
*)
	usage
	;;
esac

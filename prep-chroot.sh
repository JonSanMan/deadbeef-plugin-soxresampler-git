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
	if [[ $EUID == 0 ]]; then {
		echo "This script should not be ran as root"
		return -1
	}
	fi
}

prepchroot() {
	# Some commands need to be ran as root inside the chroot
	cat > "$TMPDIR/insidechroot.sh" <<EOF
#!/bin/bash
echo "builduser:x:1000:1000:builduser:/build:/bin/bash" >> /etc/passwd
echo "builduser:x:1000:" >> /etc/group
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_CA.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
EOF
	chmod +x "$TMPDIR/insidechroot.sh"
}

create() {
	mkdir -p "$TMPDIR/var/lib/pacman"
	sudo pacman -r "$TMPDIR" -Sy base-devel
	sudo mount proc "$TMPDIR/proc" -t proc -o nosuid,noexec,nodev
	sudo mount sys "$TMPDIR/sys" -t sysfs -o nosuid,noexec,nodev,ro
	sudo mount udev "$TMPDIR/dev" -t devtmpfs -o mode=0755,nosuid
	sudo mount devpts "$TMPDIR/dev/pts" -t devpts -o mode=0620,gid=5,nosuid,noexec

	mkdir "$TMPDIR/build"
	cp ~/.makepkg.conf "$TMPDIR/build/.makepkg.conf"

	prepchroot
	sudo chroot "$TMPDIR" "/insidechroot.sh"

	echo "Build chroot prepared"
	echo "Invoke 'pacman -r $TMPDIR --cache-dir $TMPDIR/var/cache/pacman/pkg'"
	echo "  to install additional dependancies into the chroot"
	echo ""
	echo "Invoke 'sudo -u builduser makepkg' while chrooted to run makepkg"
	echo ""
	echo "To remove chroot, launch script with clean action"
}

clean() {
	sudo umount "$TMPDIR/dev/pts"
	sudo umount "$TMPDIR/dev"
	sudo umount "$TMPDIR/sys"
	sudo umount "$TMPDIR/proc"
}

usage() {
	echo "Usage: $0 create|clean"
	echo ""
	echo "create: creates a build chroot"
	echo "clean: cleans the system mounts for a build chroot"
}

checkroot

case $1 in
create)
	create
	;;
clean)
	clean
	;;
*)
	usage
	;;
esac

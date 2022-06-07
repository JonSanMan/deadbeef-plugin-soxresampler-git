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
EOF
	chmod +x "$TMPDIR/insidechroot.sh"
}

checkroot

mkdir -p "$TMPDIR/var/lib/pacman"
sudo pacman -r "$TMPDIR" -Sy base-devel

mkdir "$TMPDIR/build"
cp ~/.makepkg.conf "$TMPDIR/build/.makepkg.conf"

prepchroot
sudo chroot "$TMPDIR" "/insidechroot.sh"

echo "Build chroot prepared"
echo "Invoke 'pacman -r $TMPDIR --cache-dir $TMPDIR/var/cache/pacman/pkg'"
echo "  to install additional dependancies into the chroot"
echo ""
echo "Invoke 'sudo -u builduser makepkg' while chrooted to run makepkg"

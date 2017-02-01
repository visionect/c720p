# FOR ACER C720 WITHOUT TOUCH PANEL
# FROM ChrUbuntu - cros-haswell-modules.sh
# https://97e83d70d72c338a5120d68abf78ce7c7e07d6e7.googledrive.com/host/0B0YvUuHHn3MndlNDbXhPRlB2eFE/cros-haswell-modules.sh
# Create a temp directory for our work
tempbuild=`mktemp -d`
cd $tempbuild

# Determine kernel version (with and without Ubuntu-specific suffix)
mykern=${1:-$(uname -r)}
mykernver=linux-$(echo $mykern | cut -d'-' -f 1)

# Install necessary deps to build a kernel
sudo apt-get build-dep -y --no-install-recommends linux-image-$mykern

# Grab Ubuntu kernel source
apt-get source linux-image-$mykern
cd $mykernver

if [ -f drivers/platform/x86/chromeos_laptop.c ]; then
  platform_folder=x86
elif [ -f drivers/platform/chrome/chromeos_laptop.c ]; then
  platform_folder=chrome
fi

# Use Benson Leung's post-Pixel Chromebook patches:
# https://patchwork.kernel.org/bundle/bleung/chromeos-laptop-deferring-and-haswell/
for patch in 3078491 3078481 3074391 3074441 3074421 3074401 3074431 3074411; do
  wget -O - https://patchwork.kernel.org/patch/$patch/raw/ \
  | sed "s/drivers\/platform\/x86\/chromeos_laptop.c/drivers\/platform\/$platform_folder\/chromeos_laptop.c/g" \
  | patch -p1
done

# Need this
cp /usr/src/linux-headers-$mykern/Module.symvers .

# Prep tree
cp /boot/config-$mykern ./.config
make oldconfig
make prepare
make modules_prepare

# Build only the needed directories
make SUBDIRS=drivers/platform/$platform_folder modules
make SUBDIRS=drivers/i2c/busses modules

# switch to using our new chromeos_laptop.ko module
# preserve old as .orig
sudo mv /lib/modules/$mykern/kernel/drivers/platform/$platform_folder/chromeos_laptop.ko /lib/modules/$mykern/kernel/drivers/platform/$platform_folder/chromeos_laptop.ko.orig
sudo cp drivers/platform/$platform_folder/chromeos_laptop.ko /lib/modules/$mykern/kernel/drivers/platform/$platform_folder/

# switch to using our new designware i2c modules
# preserve old as .orig
sudo mv /lib/modules/$mykern/kernel/drivers/i2c/busses/i2c-designware-core.ko /lib/modules/$mykern/kernel/drivers/i2c/busses/i2c-designware-core.ko.orig
sudo mv /lib/modules/$mykern/kernel/drivers/i2c/busses/i2c-designware-pci.ko /lib/modules/$mykern/kernel/drivers/i2c/busses/i2c-designware-pci.ko.orig
sudo mv /lib/modules/$mykern/kernel/drivers/i2c/busses/i2c-designware-platform.ko /lib/modules/$mykern/kernel/drivers/i2c/busses/i2c-designware-platform.ko.orig
sudo cp drivers/i2c/busses/i2c-designware-*.ko /lib/modules/$mykern/kernel/drivers/i2c/busses/
sudo depmod -a $mykern
echo "Finished building Chromebook modules in $tempbuild. Reboot to use them."
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

# fetch the chromeos_laptop and atmel maxtouch source code
# Copy made from chromium.googlesource.com chromeos-3.8 branch
# https://chromium.googlesource.com/chromiumos/third_party/kernel-next/+/refs/heads/chromeos-3.8
wget https://googledrive.com/host/0BxMvXgjEztvAbEdYM1o0ck5rOVE --output-document=patch_atmel_mxt_ts.c
wget https://googledrive.com/host/0BxMvXgjEztvAdVBjQUljYWtiR2c --output-document=patch_chromeos_laptop.c

# copy source files into kernel tree replacing existing Ubuntu source
# Patching with SED due to issues with 3.13 kernel
sed -e 's/INIT_COMPLETION(/reinit_completion(\&/g' ./patch_atmel_mxt_ts.c > drivers/input/touchscreen/atmel_mxt_ts.c
cp ./patch_chromeos_laptop.c drivers/platform/chrome/chromeos_laptop.c

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
make SUBDIRS=drivers/input/touchscreen modules

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

# switch to using our new atmel_mxt_ts.ko module
# preserve old as .orig
sudo mv /lib/modules/$mykern/kernel/drivers/input/touchscreen/atmel_mxt_ts.ko /lib/modules/$mykern/kernel/drivers/input/touchscreen/atmel_mxt_ts.ko.orig
sudo cp drivers/input/touchscreen/atmel_mxt_ts.ko /lib/modules/$mykern/kernel/drivers/input/touchscreen/

sudo depmod -a $mykern

echo "Finished building Chromebook modules in $tempbuild. Reboot to use them."

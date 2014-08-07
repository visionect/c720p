Acer c720p + Ubuntu 14.04 guide
===============================

This guide has been created for owners of Acer C720P Chromebook that would like to replace ChromeOS with native Ubuntu 14.04. It should help you with installation and enabling full hardware support for touch pad and touch panel. 

*DISCLAIMER: This guide has been built for internal use with a fresh 14.04 LTS 64bit Ubuntu and Acer C720P (with touchscreen). While we're [good developers](http://www.visionect.com), we are no Linux kernel developers, Ubuntu maintainers or Acer support line. This guide has been built using the STFW method ([risky](http://en.wiktionary.org/wiki/STFW)) and following this guide will obliterate ChromeOS and void your warranty (you will be opening your laptop). You need to have some computing experience - if you don't, find someone who does.*


1. First step: 
--------------
Removing Chrome and installing Ubuntu. Follow the guide on the awesome Arch Linux page dedicated to C720P: https://wiki.archlinux.org/index.php/Acer_C720_Chromebook. You need to remove the write protect screw (see 1.1.), enable developer mode (see 1.2.) and set seabios on by default (see 1.3.).

Reboot the laptop, pop in an Ubuntu bootable and install it. You will not have touchpanel or touchpad after the boot so either be very savy with your keyboard-Fu or get a USB mouse ready.

2. Hardware support:
---------------------
 * Touch pad and touch panel
 
 While Arch users have it good with the scripts fully prepped, we had to do some digging across the net to find a workable solution for the touch pad and touch panel under the 3.13 kernel, which is default in 14.04 LTS. [Motley slate's google+ page](https://plus.google.com/114358706658341629084/posts/Q9B4DiqWZ5E) provides the best starting point - there is a script which sadly breaks under 3.13 kernel. We've coupled that source with the patches we found on Arch page and finally implementing the patches from [Fedora](https://bugzilla.redhat.com/show_bug.cgi?id=1045821#c14).

 Run:
 ```
 wget https://raw.githubusercontent.com/visionect/c720p/master/files/ubuntu-1404_3.13-c720p-modules.sh 
 sudo chmod +x ubuntu-1404_3.13-c720p-modules.sh 
 sudo ./ubuntu-1404_3.13-c720p-modules.sh 
 ```
 Wait and reboot.

 * The rest of hardware

 There is a bunch of things that won't work out of the box. Thanks to [Simon Lister](https://plus.google.com/103687638178763248215/posts/U7qa2QysR14) we have a couple of fixes ready. First - to fix the suspend feature:
 ```
 wget https://raw.githubusercontent.com/visionect/c720p/master/files/05_sound
 sudo cp 05_sound /etc/pm/sleep.d/
 sudo chmod +x /etc/pm/sleep.d/05_sound
 ```

 The rest is a direct copy-paste from [Simon Lister's page](https://plus.google.com/103687638178763248215/posts/U7qa2QysR14)
 
 Now edit the rc.local file by typing:
 ```
 sudo gedit /etc/rc.local
 ```
 Into the gedit window type/paste the following lines above the line that says "exit 0":
 ```
 echo EHCI > /proc/acpi/wakeup
 echo HDEF > /proc/acpi/wakeup
 echo XHCI > /proc/acpi/wakeup
 echo LID0 > /proc/acpi/wakeup
 echo TPAD > /proc/acpi/wakeup
 echo TSCR > /proc/acpi/wakeup
 # 1000 corresponds to 100% backlight
 echo 1000 > /sys/class/backlight/intel_backlight/brightness
 rfkill block bluetooth
 /etc/init.d/bluetooth stop
 ```
 Save the file and exit gedit.
 Now edit the grub file by typing:
 ```
 sudo gedit /etc/default/grub
 ```
 Edit the line that says: 
 ```
 GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
 ```
 So that it reads: 
 ```
 GRUB_CMDLINE_LINUX_DEFAULT="quiet splash tpm_tis.force=1"
 ```
 Save the file and exit gedit. Then update grub by typing the following two lines:
 ```
 sudo update-grub
 sudo update-grub2
 ```
 * Preventing future updates to Kernel

 A bunch of stuff we just did are plain ol' hacks. They are tied to the specific version of Kernel that we're currently using. We'd like to prevent auto-updates messing everything up, so we can use [the guide on askubuntu](http://askubuntu.com/questions/178324/how-to-skip-kernel-update) and lock the version by typing:
 ```
 echo $(dpkg -l "*$(uname -r)*" | grep image-3 | awk '{print $2}') hold | dpkg --set-selections
 ```

3. Further reading
------------------

 * Awesome Arch linux how to: https://wiki.archlinux.org/index.php/Acer_C720_Chromebook
 * Simon Lister's G+ page: https://plus.google.com/103687638178763248215/posts/U7qa2QysR14
 * Motley Slate's G+ page: https://plus.google.com/114358706658341629084/posts/Q9B4DiqWZ5E
 * Replacing the BIOS with a custom variant to remove "Danger" bootup screens: https://plus.google.com/communities/112479827373921524726
 * Nice 13.10 guide with hacks for various hardware: http://www.reddit.com/r/chrubuntu/comments/1rsxkd/list_of_fixes_for_xubuntu_1310_on_the_acer_c720/


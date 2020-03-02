#!/bin/bash
# This script can be used to create simple chroot environment
# Written by LinuxCareer.com <http://linuxcareer.com/>
# (c) 2013 LinuxCareer under GNU GPL v3.0+

#!/bin/bash

CHROOT=$1
mkdir -p $CHROOT
echo chroot: $CHROOT

for i in $( ldd ${@:2} | grep -v dynamic | cut -d " " -f 3 | sed 's/://' | sort | uniq )
  do
    cp --parents $i $CHROOT
  done

# amd64
if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
   cp --parents /lib64/ld-linux-x86-64.so.2 /$CHROOT
fi

echo "Chroot jail is ready. To access it execute: chroot $CHROOT"
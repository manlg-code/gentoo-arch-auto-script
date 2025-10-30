#!/usr/bin/bash

list_part=$(lsblk -f)

echo -e "\n\e[93m$list_part\n\e[0m"
echo -ne '\e[95mCHOOSE DISK \e[93mNAME\e[95m THAT CONTAIN ROOT:\e[0m '
read disk_name

echo -e "\n\e[97mYou have selected the partition /dev/$disk_name\e[0m\n"

echo -ne '\e[95mTYPE IN THE MOUNT \e[93mPOINT\e[95m:\e[0m '
read mount_point

echo -e "\n\e[97mYou have selected the mount point $mount_point\e[0m\n"

export mount_root=$( echo "mount /dev/$disk_name $mount_point"   )
export       proc=$( echo "mount -t proc proc $mount_point/proc" )
export        dev=$( echo "mount --rbind /dev $mount_point/dev && mount --make-rslave $mount_point/dev")
export        sys=$( echo "mount --rbind /sys $mount_point/sys && mount --make-rslave $mount_point/sys")
export        run=$( echo "mount --rbind /run $mount_point/run && mount --make-rslave $mount_point/run")

echo -e "$mount_root\n$proc\n$dev\n$sys\n$run"
echo -ne '\n\e[95mThese commands will be executed, continue? \e[93m(yes/no)\e[95m:\e[0m'
read confirm

                                                 if [ "$confirm" = "yes" ] ; then
                                                       echo "executing..." ;
mount | grep /dev/$disk_name    | grep -q $mount_point || eval $mount_root ; 
mount | grep -q $mount_point/proc                      || eval $proc       ;
mount | grep -q $mount_point/dev                       || eval $dev        ;
mount | grep -q $mount_point/sys                       || eval $sys        ;
mount | grep -q $mount_point/run                       || eval $run        ;
                                                       chroot $mount_point ; else
                                                                      exit ; fi

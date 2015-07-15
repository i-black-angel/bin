#!/bin/bash

#----------------
# options
USERID=1000
GID=1000
CMD=mount

#----------------
# type
# if totle parameters is less than 1, then exit
if [ $# -lt 1 ]; then 
    echo "Usage: mm device"
    exit 1
fi
#----------------
# using 'blkfile' to consider what's the file type
# 0 -- block special
# 1 -- iso9660 imagefile
# 3 -- another file (unsupported)
blkfile=3

file_type=`file "$1"`
iso9660_type=`file "$1" | grep "# ISO 9660"`
if [ "$file_type" = "$1: block special" ]; then
    blkfile=0
fi
if [ -n "$iso9660_type" ]; then
    blkfile=1
fi

if [ $blkfile -gt 1 ]; then
    echo "$1 is not mountable file."
    exit 1
fi

#------------------------------
# 'blkid' will display the block info like this:
#
#  $ blkid /dev/sdb3
#  /dev/sdb3: LABEL="winning" UUID="31C438998387F4DCB" TYPE="ntfs" 
#  or
#  $ blkid /dev/sdb1
#  /dev/sdb1 UUID="789CF9998DA88" TYPE="ext4"
#
# So I chose the second content using `awk -F '"' '{print $2}'` command
# to get it for directory name, it's made under the '/mnt' dir.
# And identify type by using last content.
block_info=`blkid "$1"`
if [ -z "$block_info" ]; then
    echo "Can not get block id from: $1"
    exit 1
fi

dir_name=`blkid "$1" | awk -F '"' '{print $2}'`
if [ ! -d "/mnt/$dir_name" ]; then
    mkdir "/mnt/$dir_name"
fi

fs_type=`blkid "$1" | awk -F '"' '{print $(NF-1)}'`
# device
DEVICE=$1
# directory
DIR=/mnt/$dir_name

display_info () 
{
    echo "$DEVICE,$fs_type,$DIR"
}
case "$fs_type" in
"iso9660" )
    if [ $blkfile -eq 0 ]; then
        ${CMD} -t iso9660 -o ro,nosuid,nodev,uhelper=udisks,uid=${USERID},gid=${GID},iocharset=utf8,mode=0400,dmode=0500 ${DEVICE} "${DIR}"
        display_info
    else 
        ${CMD} -t iso9660 -o loop,ro,nosuid,nodev,uhelper=udisks,uid=${USERID},gid=${GID},iocharset=utf8,mode=0400,dmode=0500 ${DEVICE} "${DIR}"
        display_info
    fi;;
"udf" )
    if [ $blkfile -eq 0 ]; then
        ${CMD} -t udf -o ro,nosuid,nodev,uhelper=udisks,uid=${USERID},gid=${GID},iocharset=utf8 ${DEVICE} "${DIR}"
        display_info
    else 
        ${CMD} -t udf -o loop,ro,nosuid,nodev,uhelper=udisks,uid=${USERID},gid=${GID},iocharset=utf8 ${DEVICE} "${DIR}"
        display_info
    fi;;
"vfat" )
    ${CMD} -t vfat -o rw,nosuid,nodev,uhelper=udisks,uid=${USERID},gid=${GID},shortname=mixed,dmask=0077,utf8=1,showexec,flush ${DEVICE} "${DIR}"
    display_info;;
"ntfs" )
    ntfsmount ${DEVICE} "${DIR}" -o uid=${USERID},gid=${GID}
    display_info;;
"ext4" )
    ${CMD} -t ext4 -o rw,nosuid,nodev,uhelper=udisks ${DEVICE} "${DIR}"
    display_info;;
"ext3" )
    ${CMD} -t ext3 -o rw,nosuid,nodev,uhelper=udisks ${DEVICE} "${DIR}"
    display_info;;
* ) if [ -d "${DIR}" ]; then
        rm -r "${DIR}"
    fi
    echo "Sorry, you have to use 'mount' command instead of this shell.";;
esac

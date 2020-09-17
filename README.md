# lfs-scripts :penguin:
Instructions and scripts to build LFS (Linux From Scratch), version 10.0, as simply as possible (I know, not that simple, but anyway).

# Foreword

First, this guide does not replace reading the whole LFS book. I highly recommend that you read it at least once. Only then you should use the automation scripts provided here.

This build will be accomplished inside a virtual machine. I'll be using Oracle VirtualBox, but you can use the tool of your personal preference. I'm running an Arch Linux VM, feel free to use your GNU/Linux distribution of choice. Just be sure to install the development tools available (base-devel package on Arch).

My VM has two virtual hard disks: one for the host (Arch Linux itself) and another for building LFS. You could also use a single hard disk with two partitions, that's also up to personal taste. I've decided to use two separate hard disks so I can completely isolate LFS from the host after the build. At the end, you'll be able to create a separate VM and boot from it directly.

The packages needed to build LFS were downloaded from [here](http://ftp.lfs-matrix.net/pub/lfs/lfs-packages/lfs-packages-10.0.tar) (423 MB), other mirrors are available [here](http://linuxfromscratch.org/lfs/download.html)

# Build instructions

:point_right: Run commands below as root.

Create a partition and a filesystem in the virtual hard disk (/dev/sdb):

```
mkdir /mnt/lfs
fdisk /dev/sdb
```

Use the following basic options:

n- new partition
<Enter> for all default values
w- write changes

Create a filesystem, a mount point, and mount it:

```
mkfs.ext4 /dev/sdb1
mkdir /mnt/lfs
mount /dev/sdb1 /mnt/lfs
```

Add the following line to root's .bashrc:

```
export LFS=/mnt/lfs
```

Source the file:

```
source .bashrc
```

Download all the packages and extract them to $LFS/sources.

```
cd $LFS
cp /<location_of_the_package>/lfs-packages-10.0.tar .
tar xf lfs-packages-10.0.tar
mv 10.0 sources
chmod -v a+wt $LFS/sources
```

Create the basic filesystem for LFS:

```
mkdir -pv $LFS/{bin,etc,lib,sbin,usr,var,lib64,tools}
```

Create the lfs user, used during the initial build process (you will have to type a password):

```
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
passwd lfs
```

Make lfs own the entire filesystem:

```
chown -R lfs:lfs $LFS/*
chown lfs:lfs $LFS
```

Login as the lfs user:

```
su - lfs
```

Create a .bash_profile file:

```
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
```

Create a .bashrc file:

```
cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
export LFS LC_ALL LFS_TGT PATH
EOF

source ~/.bashrc
```

Copy all the shell scripts from this repository to your $LFS directory:

```
cp /<location_of_the_scripts>/*.sh $LFS
```

Now, run the lfs-cross.sh script, which will build the cross-toolchain and cross compiling temporary tools from chapters 5 and 6. The build took approximately 30 minutes on my machine:

```
cd $LFS
sh lfs-cross.sh | tee lfs-cross.log
```

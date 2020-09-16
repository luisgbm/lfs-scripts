# lfs-scripts
Instructions and scripts to build LFS (Linux From Scratch) 10.0 as simply as possible

# Foreword

First, this guide does not replace reading the whole LFS book. I highly recommend that you read it, at least once, and then go to the automation scripts provided here.

This build will be done inside a virtual machine, for that I'll be using Oracle VirtualBox, but you can use the tool you prefer. I'm running an Arch Linux VM, feel free to use your GNU/Linux distro of preference. Just be sure to install the development tools (base-devel package on Arch).

My VM has two virtual hard disks: one for the host (Arch Linux itself) and another for building LFS. You could also use a single hard disk with two partitions, that's up to personal preference. I've decided to use two separate hard disks so I can completely isolate LFS from the host after the build. At the end, you'll be able to create a separate VM and boot it.

The packages needed to build LFS were obtained from ftp://ftp.lfs-matrix.net/pub/lfs/lfs-packages/lfs-packages-10.0.tar (423 MB), other mirrors are available at http://linuxfromscratch.org/lfs/download.html

# Build instructions

Create a partition and a filesystem in the virtual hard disk (/dev/sdb). Run commands as root:

```
mkdir /mnt/lfs
fdisk /dev/sdb
```

Use the following basic options:

n- new partition
<Enter> for all default values
w- write changes

Create a filysystem, a mount point, and mount it:

```
mkfs.ext4 /dev/sdb1
mkdir /mnt/lfs
mount /dev/sdb1 /mnt/lfs
```

Include the following command to root's .bashrc:

```
export LFS=/mnt/lfs
```

Source the file to use the variable:

```
source .bashrc
```

Download all the packages and extract them to /mnt/lfs/sources.

```
cd /mnt/lfs
cp /<location_of_the_package>/lfs-packages-10.0.tar .
tar xf lfs-packages-10.0.tar
mv 10.0 sources
chmod -v a+wt $LFS/sources
```

Create the basic filesystem:

```
mkdir -pv $LFS/{bin,etc,lib,sbin,usr,var,lib64,tools}
```

Create the lfs user, used during the initial build process:

```
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
passwd lfs
```

You will have to type a password.

Make lfs the owner of the filesystem:

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

source ~/.bash_profile
```

Copy all the scripts from this repository to your $LFS directory:

```
cp /<location_of_the_scripts>/*.sh $LFS
```

Now, run the lfs-cross.sh script, which will build the cross-toolchain and cross compiling temporary tools from chapters 5 and 6. The build took 30 min on my machine:

```
cd $LFS
sh lfs-cross.sh | tee lfs-cross.log
```

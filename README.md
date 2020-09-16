# lfs-scripts
Instructions and scripts to build LFS (Linux From Scratch) 10.0 as simply as possible

# Overall instructions

First, this guide does not replace reading the whole LFS book. I highly recommend that you read it, at least once, and then go to the automation scripts provided here.

This build will be done inside a virtual machine, for that I'll be using Oracle VirtualBox, but you can use the tool you prefer. I'm running an Arch Linux VM, feel free to use your GNU/Linux distro of preference. Just be sure to install the development tools (base-devel package on Arch).

My VM has two virtual hard disks: one for the host (Arch Linux itself) and another for building LFS. You could also use a single hard disk with two partitions, that's up to personal preference. I've decided to use two separate hard disks so I can completely isolate myself from the host after the build. At the end, you'll be able to create a separate VM and boot it.

The packages needed to build LFS were obtained in ftp://ftp.lfs-matrix.net/pub/lfs/lfs-packages/lfs-packages-10.0.tar (423 MB), other mirrors are available at http://linuxfromscratch.org/lfs/download.html

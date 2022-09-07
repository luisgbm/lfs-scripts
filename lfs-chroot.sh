#!/bin/bash
# LFS 11.2 Build Script
# Builds the additional temporary tools from chapter 7
# by Luís Mendes :)
# 06/Sep/2022

package_name=""
package_ext=""

begin() {
	package_name=$1
	package_ext=$2

	echo "[lfs-chroot] Starting build of $package_name at $(date)"

	tar xf $package_name.$package_ext
	cd $package_name
}

finish() {
	echo "[lfs-chroot] Finishing build of $package_name at $(date)"

	cd /sources
	rm -rf $package_name
}

cd /sources

# 7.7. Gettext-0.21
begin gettext-0.21 tar.xz
./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
finish

# 7.8. Bison-3.8.2
begin bison-3.8.2 tar.xz
./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2
make
make install
finish

# 7.9. Perl-5.36.0
begin perl-5.36.0 tar.xz
sh Configure -des                                        \
             -Dprefix=/usr                               \
             -Dvendorprefix=/usr                         \
             -Dprivlib=/usr/lib/perl5/5.36/core_perl     \
             -Darchlib=/usr/lib/perl5/5.36/core_perl     \
             -Dsitelib=/usr/lib/perl5/5.36/site_perl     \
             -Dsitearch=/usr/lib/perl5/5.36/site_perl    \
             -Dvendorlib=/usr/lib/perl5/5.36/vendor_perl \
             -Dvendorarch=/usr/lib/perl5/5.36/vendor_perl
make
make install
finish

# 7.10. Python-3.10.6
begin Python-3.10.6 tar.xz
./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip
make
make install
finish

# 7.11. Texinfo-6.8
begin texinfo-6.8 tar.xz
./configure --prefix=/usr
make
make install
finish

# 7.12. Util-linux-2.38.1
begin util-linux-2.38.1 tar.xz
mkdir -pv /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime    \
            --libdir=/usr/lib    \
            --docdir=/usr/share/doc/util-linux-2.38.1 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            runstatedir=/run
make
make install
finish

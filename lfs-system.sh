#!/bin/bash
# LFS 11.2 Build Script
# Builds the basic system software from chapter 8
# by Luís Mendes :)
# 07/Sep/2022

package_name=""
package_ext=""

begin() {
	package_name=$1
	package_ext=$2

	echo "[lfs-system] Starting build of $package_name at $(date)"

	tar xf $package_name.$package_ext
	cd $package_name
}

finish() {
	echo "[lfs-system] Finishing build of $package_name at $(date)"

	cd /sources
	rm -rf $package_name
}

cd /sources

# 8.3. Man-pages-5.13
begin man-pages-5.13 tar.xz
make prefix=/usr install
finish

# 8.4. Iana-Etc-20220812
begin iana-etc-20220812 tar.gz
cp services protocols /etc
finish

# 8.5. Glibc-2.36
begin glibc-2.36 tar.xz
patch -Np1 -i ../glibc-2.36-fhs-1.patch
mkdir -v build
cd       build
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-kernel=3.2                      \
             --enable-stack-protector=strong          \
             --with-headers=/usr/include              \
             libc_cv_slibdir=/usr/lib
make
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
make localedata/install-locales

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../../tzdata2022c.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO
ln -sfv /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF

mkdir -pv /etc/ld.so.conf.d
finish

# 8.6. Zlib-1.2.12
begin zlib-1.2.12 tar.xz
./configure --prefix=/usr
make
make install
rm -fv /usr/lib/libz.a
finish

# 8.7. Bzip2-1.0.8
begin bzip2-1.0.8 tar.gz
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install
cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
rm -fv /usr/lib/libbz2.a
finish

# 8.8. Xz-5.2.6
begin xz-5.2.6 tar.xz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.6
make
make install
finish

# 8.9. Zstd-1.5.2
begin zstd-1.5.2 tar.gz
patch -Np1 -i ../zstd-1.5.2-upstream_fixes-1.patch
make prefix=/usr
make prefix=/usr install
rm -v /usr/lib/libzstd.a
finish

# 8.10. File-5.42
begin file-5.42 tar.gz
./configure --prefix=/usr
make
make install
finish

# 8.11. Readline-8.1.2
begin readline-8.1.2 tar.gz
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.1.2
make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.1.2
finish

# 8.12. M4-1.4.19
begin m4-1.4.19 tar.xz
./configure --prefix=/usr
make
make install
finish

# 8.13. Bc-6.0.1
begin bc-6.0.1 tar.xz
CC=gcc ./configure --prefix=/usr -G -O3 -r
make
make install
finish

# 8.14. Flex-2.6.4
begin flex-2.6.4 tar.gz
./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static
make
make install
ln -sv flex /usr/bin/lex
finish

# 8.15. Tcl-8.6.12
mv tcl8.6.12-src.tar.gz tcl8.6.12.tar.gz
begin tcl8.6.12 tar.gz
tar -xf ../tcl8.6.12-html.tar.gz --strip-components=1
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man
make

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.3|/usr/lib/tdbc1.1.3|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.3/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.3/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.3|/usr/include|"            \
    -i pkgs/tdbc1.1.3/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.2|/usr/lib/itcl4.2.2|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.2/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.2.2|/usr/include|"            \
    -i pkgs/itcl4.2.2/itclConfig.sh

unset SRCDIR
make install
chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3
mkdir -v -p /usr/share/doc/tcl-8.6.12
cp -v -r  ../html/* /usr/share/doc/tcl-8.6.12
finish

# 8.16. Expect-5.45.4
begin expect5.45.4 tar.gz
./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include
make
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
finish

# 8.17. DejaGNU-1.6.3
begin dejagnu-1.6.3 tar.gz
mkdir -v build
cd       build
../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi
make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3
finish

# 8.18. Binutils-2.39
begin binutils-2.39 tar.xz
expect -c "spawn ls"
mkdir -v build
cd       build
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib
make tooldir=/usr
make tooldir=/usr install
rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes}.a
finish

# 8.19. GMP-6.2.1
begin gmp-6.2.1 tar.xz
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.2.1
make
make html
make install
make install-html
finish

# 8.20. MPFR-4.1.0
begin mpfr-4.1.0 tar.xz
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.1.0
make
make html
make install
make install-html
finish

# 8.21. MPC-1.2.1
begin mpc-1.2.1 tar.gz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.2.1
make
make html
make install
make install-html
finish

# 8.22. Attr-2.5.1
begin attr-2.5.1 tar.gz
./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.1
make
make install
finish

# 8.23. Acl-2.3.1
begin acl-2.3.1 tar.xz
./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/acl-2.3.1
make
make install
finish

# 8.24. Libcap-2.65
begin libcap-2.65 tar.xz
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib
make prefix=/usr lib=lib install
finish

# 8.25. Shadow-4.12.2
begin shadow-4.12.2 tar.xz
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD SHA512:' \
    -e 's:/var/spool/mail:/var/mail:'                 \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                \
    -i etc/login.defs
touch /usr/bin/passwd
./configure --sysconfdir=/etc \
            --disable-static  \
            --with-group-name-max-length=32
make
make exec_prefix=/usr install
make -C man install-man
finish

# 8.26. GCC-12.2.0
begin gcc-12.2.0 tar.xz
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
mkdir -v build
cd       build
../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --disable-multilib       \
             --disable-bootstrap      \
             --with-system-zlib
make
make install
chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/12.2.0/include{,-fixed}
ln -svr /usr/bin/cpp /usr/lib
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/12.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
grep -B4 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log
rm -v dummy.c a.out dummy.log
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
finish

# 8.27. Pkg-config-0.29.2
begin pkg-config-0.29.2 tar.gz
./configure --prefix=/usr              \
            --with-internal-glib       \
            --disable-host-tool        \
            --docdir=/usr/share/doc/pkg-config-0.29.2
make
make install
finish

# 8.28. Ncurses-6.3
begin ncurses-6.3 tar.gz
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --enable-widec          \
            --with-pkg-config-libdir=/usr/lib/pkgconfig
make
make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/libncursesw.so.6.3 /usr/lib
rm -v  dest/usr/lib/libncursesw.so.6.3
cp -av dest/* /
for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done
rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so
mkdir -pv      /usr/share/doc/ncurses-6.3
cp -v -R doc/* /usr/share/doc/ncurses-6.3
finish

# 8.29. Sed-4.8
begin sed-4.8 tar.xz
./configure --prefix=/usr
make
make html
make install
install -d -m755           /usr/share/doc/sed-4.8
install -m644 doc/sed.html /usr/share/doc/sed-4.8
finish

# 8.30. Psmisc-23.5
begin psmisc-23.5 tar.xz
./configure --prefix=/usr
make
make install
finish

# 8.31. Gettext-0.21
begin gettext-0.21 tar.xz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.21
make
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so
finish

# 8.32. Bison-3.8.2
begin bison-3.8.2 tar.xz
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
make
make install
finish

# 8.33. Grep-3.7
begin grep-3.7 tar.xz
./configure --prefix=/usr
make
make install
finish

# 8.34. Bash-5.1.16
begin bash-5.1.16 tar.gz
./configure --prefix=/usr                      \
            --docdir=/usr/share/doc/bash-5.1.16 \
            --without-bash-malloc              \
            --with-installed-readline
make
make install
finish

# 8.35. Libtool-2.4.7
begin libtool-2.4.7 tar.xz
./configure --prefix=/usr
make
make install
rm -fv /usr/lib/libltdl.a
finish

# 8.36. GDBM-1.23
begin gdbm-1.23 tar.gz
./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat
make
make install
finish

# 8.37. Gperf-3.1
begin gperf-3.1 tar.gz
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
make
make install
finish

# 8.38. Expat-2.4.8
begin expat-2.4.8 tar.xz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.4.8
make
make install
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.4.8
finish

# 8.39. Inetutils-2.3
begin inetutils-2.3 tar.xz
./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers
make
make install
mv -v /usr/{,s}bin/ifconfig
finish

# 8.40. Less-590
begin less-590 tar.gz
./configure --prefix=/usr --sysconfdir=/etc
make
make install
finish

# 8.41. Perl-5.36.0
begin perl-5.36.0 tar.xz
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des                                         \
             -Dprefix=/usr                                \
             -Dvendorprefix=/usr                          \
             -Dprivlib=/usr/lib/perl5/5.36/core_perl      \
             -Darchlib=/usr/lib/perl5/5.36/core_perl      \
             -Dsitelib=/usr/lib/perl5/5.36/site_perl      \
             -Dsitearch=/usr/lib/perl5/5.36/site_perl     \
             -Dvendorlib=/usr/lib/perl5/5.36/vendor_perl  \
             -Dvendorarch=/usr/lib/perl5/5.36/vendor_perl \
             -Dman1dir=/usr/share/man/man1                \
             -Dman3dir=/usr/share/man/man3                \
             -Dpager="/usr/bin/less -isR"                 \
             -Duseshrplib                                 \
             -Dusethreads
make
make install
unset BUILD_ZLIB BUILD_BZIP2
finish

# 8.42. XML::Parser-2.46
begin XML-Parser-2.46 tar.gz
perl Makefile.PL
make
make install
finish

# 8.43. Intltool-0.51.0
begin intltool-0.51.0 tar.gz
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
finish

# 8.44. Autoconf-2.71
begin autoconf-2.71 tar.xz
./configure --prefix=/usr
make
make install
finish

# 8.45. Automake-1.16.5
begin automake-1.16.5 tar.xz
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5
make
make install
finish

# 8.46. OpenSSL-3.0.5
begin openssl-3.0.5 tar.gz
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
make
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.0.5
cp -vfr doc/* /usr/share/doc/openssl-3.0.5
finish

# 8.47. Kmod-30
begin kmod-30 tar.xz
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --with-openssl         \
            --with-xz              \
            --with-zstd            \
            --with-zlib
make
make install
for target in depmod insmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /usr/sbin/$target
done
ln -sfv kmod /usr/bin/lsmod
finish

# 8.48. Libelf from Elfutils-0.187
begin elfutils-0.187 tar.bz2
./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy
make
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a
finish

# 8.49. Libffi-3.4.2
begin libffi-3.4.2 tar.gz
./configure --prefix=/usr          \
            --disable-static       \
            --with-gcc-arch=native \
            --disable-exec-static-tramp
make
make install
finish

# 8.50. Python-3.10.6
begin Python-3.10.6 tar.xz
./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --with-system-ffi    \
            --enable-optimizations
make
make install
cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF
install -v -dm755 /usr/share/doc/python-3.10.6/html
tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.10.6/html \
    -xvf ../python-3.10.6-docs-html.tar.bz2
finish

# 8.51. Wheel-0.37.1
begin wheel-0.37.1 tar.gz
pip3 install --no-index $PWD
finish

# 8.52. Ninja-1.11.0
begin ninja-1.11.0 tar.gz
sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc
python3 configure.py --bootstrap
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
finish

# 8.53. Meson-0.63.1
begin meson-0.63.1 tar.gz
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
finish

# 8.54. Coreutils-9.1
begin coreutils-9.1 tar.xz
patch -Np1 -i ../coreutils-9.1-i18n-1.patch
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
make
make install
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
finish

# 8.55. Check-0.15.2
begin check-0.15.2 tar.gz
./configure --prefix=/usr --disable-static
make
make docdir=/usr/share/doc/check-0.15.2 install
finish

# 8.56. Diffutils-3.8
begin diffutils-3.8 tar.xz
./configure --prefix=/usr
make
make install
finish

# 8.57. Gawk-5.1.1
begin gawk-5.1.1 tar.xz
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
make
make install
mkdir -pv                                   /usr/share/doc/gawk-5.1.1
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.1.1
finish

# 8.58. Findutils-4.9.0
begin findutils-4.9.0 tar.xz
case $(uname -m) in
    i?86)   TIME_T_32_BIT_OK=yes ./configure --prefix=/usr --localstatedir=/var/lib/locate ;;
    x86_64) ./configure --prefix=/usr --localstatedir=/var/lib/locate ;;
esac
make
make install
finish

# 8.59. Groff-1.22.4
begin groff-1.22.4 tar.gz
PAGE=A4 ./configure --prefix=/usr
make -j1
make install
finish

# 8.60. GRUB-2.06
begin grub-2.06 tar.xz
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror
make
make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
finish

# 8.61. Gzip-1.12
begin gzip-1.12 tar.xz
./configure --prefix=/usr
make
make install
finish

# 8.62. IPRoute2-5.19.0
begin iproute2-5.19.0 tar.xz
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
make NETNS_RUN_DIR=/run/netns
make SBINDIR=/usr/sbin install
mkdir -pv             /usr/share/doc/iproute2-5.19.0
cp -v COPYING README* /usr/share/doc/iproute2-5.19.0
finish

# 8.63. Kbd-2.5.1
begin kbd-2.5.1 tar.xz
patch -Np1 -i ../kbd-2.5.1-backspace-1.patch
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
./configure --prefix=/usr --disable-vlock
finish

# 8.64. Libpipeline-1.5.6
begin libpipeline-1.5.6 tar.gz
./configure --prefix=/usr
make
make install
finish

# 8.65. Make-4.3
begin make-4.3 tar.gz
./configure --prefix=/usr
make
make install
finish

# 8.66. Patch-2.7.6
begin patch-2.7.6 tar.xz
./configure --prefix=/usr
make
make install
finish

# 8.67. Tar-1.34
begin tar-1.34 tar.xz
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr
make
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.34
finish

# 8.68. Texinfo-6.8
begin texinfo-6.8 tar.xz
./configure --prefix=/usr
make
make install
make TEXMF=/usr/share/texmf install-tex
pushd /usr/share/info
  rm -v dir
  for f in *
    do install-info $f dir 2>/dev/null
  done
popd
finish

# 8.69. Vim-9.0.0228
begin vim-9.0.0228 tar.gz
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make
make install
ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim90/doc /usr/share/doc/vim-9.0.0228
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
finish

# 8.70. Eudev-3.2.11
begin eudev-3.2.11 tar.gz
./configure --prefix=/usr           \
            --bindir=/usr/sbin      \
            --sysconfdir=/etc       \
            --enable-manpages       \
            --disable-static
make
mkdir -pv /usr/lib/udev/rules.d
mkdir -pv /etc/udev/rules.d
make install
tar -xvf ../udev-lfs-20171102.tar.xz
make -f udev-lfs-20171102/Makefile.lfs install
udevadm hwdb --update
finish

# 8.71. Man-DB-2.10.2
begin man-db-2.10.2 tar.xz
./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.10.2 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap             \
            --with-systemdtmpfilesdir=            \
            --with-systemdsystemunitdir=
make
make install
finish

# 8.72. Procps-ng-4.0.0
begin procps-ng-4.0.0 tar.xz
./configure --prefix=/usr                            \
            --docdir=/usr/share/doc/procps-ng-4.0.0 \
            --disable-static                         \
            --disable-kill
make
make install
finish

# 8.73. Util-linux-2.38.1
begin util-linux-2.38.1 tar.xz
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
            --bindir=/usr/bin    \
            --libdir=/usr/lib    \
            --sbindir=/usr/sbin  \
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
            --without-systemd    \
            --without-systemdsystemunitdir
make
make install
finish

# 8.74. E2fsprogs-1.46.5
begin e2fsprogs-1.46.5 tar.gz
mkdir -v build
cd       build
../configure --prefix=/usr           \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make
make install
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
finish

# 8.75. Sysklogd-1.5.1
begin sysklogd-1.5.1 tar.gz
sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
sed -i 's/union wait/int/' syslogd.c
make
make BINDIR=/sbin install
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF
finish

# 8.76. Sysvinit-3.04
begin sysvinit-3.04 tar.xz
patch -Np1 -i ../sysvinit-3.04-consolidated-1.patch
make
make install
finish

# 8.78. Stripping
save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
             libc.so.6
             libthread_db.so.1
             libquadmath.so.0.0.0
             libstdc++.so.6.0.30
             libitm.so.1.0.0
             libatomic.so.1.2.0"

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug $LIB $LIB.dbg
    cp $LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

online_usrbin="bash find strip"
online_usrlib="libbfd-2.39.so
               libhistory.so.8.1
               libncursesw.so.6.3
               libm.so.6
               libreadline.so.8.1
               libz.so.1.2.12
               $(cd /usr/lib; find libnss*.so* -type f)"

for BIN in $online_usrbin; do
    cp /usr/bin/$BIN /tmp/$BIN
    strip --strip-unneeded /tmp/$BIN
    install -vm755 /tmp/$BIN /usr/bin
    rm /tmp/$BIN
done

for LIB in $online_usrlib; do
    cp /usr/lib/$LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
         $(find /usr/lib -type f -name \*.a)                 \
         $(find /usr/{bin,sbin,libexec} -type f); do
    case "$online_usrbin $online_usrlib $save_usrlib" in
        *$(basename $i)* )
            ;;
        * ) strip --strip-unneeded $i
            ;;
    esac
done

unset BIN LIB save_usrlib online_usrbin online_usrlib

# 8.78. Cleaning Up
rm -rf /tmp/*
find /usr/lib /usr/libexec -name \*.la -delete
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf

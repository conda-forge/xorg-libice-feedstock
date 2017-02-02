#! /bin/bash

set -e
IFS=$' \t\n' # workaround for conda 4.2.13+toolchain bug

# Adopt a Unix-friendly path if we're on Windows (see bld.bat).
[ -n "$PATH_OVERRIDE" ] && export PATH="$PATH_OVERRIDE"

# Fresh OS-guessing scripts from xorg-util-macros for win64
for f in config.guess config.sub ; do
    cp -p $PREFIX/share/util-macros/$f .
done

if [ -n "$VS_MAJOR" ] ; then
    # Need to regenerate configure scripts to properly detect msys2.
    am_version=1.15 # keep sync'ed with meta.yaml
    export ACLOCAL=aclocal-$am_version
    export AUTOMAKE=automake-$am_version
    autoreconf_args=(
        --force
        --install
        -I "$PREFIX/share/aclocal"
        -I "$PREFIX/Library/usr/share/aclocal"
        -I "$PREFIX/mingw-w$ARCH/share/aclocal"
    )
    autoreconf "${autoreconf_args[@]}"
fi

export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig
configure_args=(
    --prefix=$PREFIX
    --disable-dependency-tracking
    --disable-selective-werror
    --disable-silent-rules
)

# Unix domain sockets aren't gonna work on Windows
if [ -n "$VS_MAJOR" ] ; then
    configure_args+=(--disable-unix-transport)
fi

./configure "${configure_args[@]}"
make -j$CPU_COUNT
make install
make check

rm -rf $PREFIX/share/doc/libICE

# Prefer dynamic libraries to static, and dump libtool helper files
for lib_ident in ICE; do
    rm -f $PREFIX/lib/lib${lib_ident}.la
    if [ -e $PREFIX/lib/lib${lib_ident}$SHLIB_EXT ] ; then
        rm -f $PREFIX/lib/lib${lib_ident}.a
    fi
done

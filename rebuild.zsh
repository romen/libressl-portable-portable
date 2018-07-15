#!/usr/bin/env zsh

: ${MAKEFLAGS:=-j8}; export MAKEFLAGS
: ${CFLAGS:=-g}; export CFLAGS

function usage() {
    cat <<EOU
Usage: ${(%):-%N} <cmake|make> [options]

Options:
    -d (debug build)
    -no_asm (disable asm code)
EOU
}

function do_set_options() {
    USE=$1
    [ ! -z "$LIBRESSL_BUILD_DEBUG" ] && CFLAGS="-O0 -g ${CFLAGS}"

    if [ "$USE" = "cmake" ]; then
        LIBRESSL_CMAKE_OPTS="$LIBRESSL_CMAKE_OPTS ${_NOASM+-DENABLE_ASM=OFF}"
    elif [ "$USE" = "make" ]; then
        LIBRESSL_CONF_OPTS="$LIBRESSL_CONF_OPTS ${_NOASM+--disable-asm}"
    fi
}

function rebuild_cmake() {
    rm -rf build
    (mkdir build
     cd build && \
         cmake $(eval echo $LIBRESSL_CMAKE_OPTS) .. && \
         make && make test
    )
}

function rebuild_make() {
    ./configure $(eval echo $LIBRESSL_CONF_OPTS) && \
        make && make check
}

function do_rebuild() {
    USE=$1

    make distclean
    ./autogen.sh

    if [ "$USE" = "cmake" ]; then
        export LIBRESSL_CMAKE_OPTS
        rebuild_cmake
    elif [ "$USE" = "make" ]; then
        export LIBRESSL_CONF_OPTS
        rebuild_make
    else
        false
    fi
}

function parse_options() {
    shift
    zparseopts d=LIBRESSL_BUILD_DEBUG no_asm=_NOASM
}

if [ "$1" = "cmake" ] || [ "$1" = "make" ]; then
    USE=$1
else
    usage
    exit 255
fi

set -x


parse_options $@ && \
    do_set_options $USE && \
#    read && \
    do_rebuild $USE

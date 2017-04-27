#!/bin/bash -x
#set -e

if [ "${TRAVIS_OS_NAME}" != "osx" ]; then
    echo "This script can be used only with Mac OS X Travis"
    exit 1
fi

# prepare install prefix
PREFIX=${1}; [ -z ${PREFIX} ] && export PREFIX="${HOME}/.local"

install -d ${PREFIX}/{lib,libexec,include,bin,sbin,man,share,etc,info,doc,var,lib/pkgconfig}

# prepare build env
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}"
export PATH="${PREFIX}/bin:${PREFIX}/sbin:/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:${PATH}"
export BUILD_DIR="$(pwd)/.build-depend"
export LOG=$(pwd)/build.log
[ ! -e ${BUILD_DIR} ] && mkdir ${BUILD_DIR}; cd ${BUILD_DIR}
echo "build: ${BUILD_DIR}"
echo "log:   ${LOG}" | tee ${LOG}

function on_failure {
    cat ${LOG}
    exit 1
}
trap on_failure ERR

function fetch_pkg {
	if [ "${2##*.}" == git ]; then
		[ ! -e $1 ] && git clone "$2" $1 &> /dev/null
		cd $1; git checkout $3 &> /dev/null; cd -
	else
		[ ! -f $1.tar.${2##*.} ] && curl -L "$2" > $1.tar.${2##*.}
		tar xf $1.tar.${2##*.}
	fi
	cd $1
}

function build_pkg {
	if [ -f configure.ac ]; then
		if [ ! -e ./configure ]; then
			[ -e autogen.sh ] && sh autogen.sh || autoreconf -if
		fi
		./configure --prefix=${PREFIX} --enable-shared $* || find . -name config.log -exec cat {} \;
		make ${MAKEOPTS}
		make install
	elif [ -f CMakeLists.txt ]; then
		[ -e cmake-build ] && rm -rf cmake-build; mkdir cmake-build; cd cmake-build
		cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} ..
		make ${MAKEOPTS}
		make install
	else
		make $*
	fi
}

function pkg {
	if [ ! -e ${PREFIX}/$4 ] && [ "${BUILD_IGNORE}" == "${BUILD_IGNORE/$1/}" ] ; then
		cd ${BUILD_DIR}
		echo "[x] fetching $1-$3"
		fetch_pkg "$1-$3" "$2" $3 >> ${LOG}
		echo "[x] building $1-$3"
		shift 4
		(build_pkg $*) >> ${LOG} 2>&1
	fi
}

# Create lmdb pkg-config
cat >${PREFIX}/lib/pkgconfig/lmdb.pc <<EOF
prefix=$(brew --prefix lmdb)
exec_prefix=\${prefix}
libdir=\${prefix}/lib/
includedir=\${prefix}/include

Name: liblmdb
Description: Lightning Memory-Mapped Database
URL: https://symas.com/products/lightning-memory-mapped-database/
Version: $(brew ls --versions lmdb | awk '{print $2}')
Libs: -L${libdir} -llmdb
Cflags: -I${includedir}
EOF

FSTRM_VER="0.3.2"
FSTRM_URL="https://github.com/farsightsec/fstrm/archive/v${FSTRM_VER}.tar.gz"

pkg fstrm ${FSTRM_URL} ${FSTRM_VER} include/fstrm.h --disable-programs
echo "Build success!"

# remove on successful build
rm -rf ${BUILD_DIR}

exit 0

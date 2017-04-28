#!/bin/bash -x
#set -e

# prepare install prefix
PREFIX=${1}; [ -z ${PREFIX} ] && export PREFIX="${HOME}/.local"

install -d ${PREFIX}/lib/pkgconfig

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

echo "Build success!"

exit 0

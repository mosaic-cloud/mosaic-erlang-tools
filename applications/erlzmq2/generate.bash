#!/bin/bash

set -e -E -u -o pipefail -o noclobber -o noglob -o braceexpand || exit 1
trap 'printf "[ee] failed: %s\n" "${BASH_COMMAND}" >&2' ERR || exit 1

test "${#}" -eq 0

cd -- "$( dirname -- "$( readlink -e -- "${0}" )" )"
test -d ./.generated

cp -T ./repositories/erlzmq2/src/erlzmq.app.src ./.generated/erlzmq.app

gcc -shared -o ./.generated/erlzmq_drv.so \
		-I ./repositories/erlzmq2/c_src \
		-I "${pallur_pkg_zeromq:-/usr}/include" \
		-I "${pallur_pkg_erlang:-/usr/lib/erlang}/usr/include" \
		-L "${pallur_pkg_erlang:-/usr/lib/erlang}/usr/lib" \
		${pallur_CFLAGS:-} ${pallur_LDFLAGS:-} \
		./repositories/erlzmq2/c_src/erlzmq_nif.c \
		./repositories/erlzmq2/c_src/vector.c \
		"${pallur_pkg_zeromq:-/usr}/lib/libzmq.a" \
		-lstdc++ -luuid \
		${pallur_LIBS:-}

exit 0

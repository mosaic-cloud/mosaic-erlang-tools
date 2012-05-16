#!/bin/bash

set -e -E -u -o pipefail || exit 1
test "${#}" -eq 0

cd -- "$( dirname -- "$( readlink -e -- "${0}" )" )"

rm -Rf ./.generated
mkdir ./.generated

cp -T ./repositories/erlzmq2/src/erlzmq.app.src ./.generated/erlzmq.app

gcc -shared -o ./.generated/erlzmq_drv.so \
		-I ./repositories/erlzmq2/c_src \
		-I /usr/lib/erlang/usr/include \
		-I "${mosaic_pkg_zeromq:-/usr}/include" \
		./repositories/erlzmq2/c_src/erlzmq_nif.c \
		./repositories/erlzmq2/c_src/vector.c \
		"${mosaic_pkg_zeromq:-/usr}/lib/libzmq.a" \
		-lstdc++ -luuid

exit 0

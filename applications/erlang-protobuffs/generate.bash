#!/bin/bash

set -e -E -u -o pipefail -o noclobber -o noglob -o braceexpand || exit 1
trap 'printf "[ee] failed: %s\n" "${BASH_COMMAND}" >&2' ERR || exit 1

test "${#}" -eq 0

cd -- "$( dirname -- "$( readlink -e -- "${0}" )" )"

rm -Rf ./.generated
mkdir ./.generated

erlc -o ./.generated -b erl ./repositories/erlang-protobuffs/src/protobuffs_scanner.xrl
erlc -o ./.generated -b erl ./repositories/erlang-protobuffs/src/protobuffs_parser.yrl

cp -T ./repositories/erlang-protobuffs/src/protobuffs.app.src ./.generated/protobuffs.app

exit 0

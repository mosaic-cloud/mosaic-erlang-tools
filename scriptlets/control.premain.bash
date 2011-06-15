#!/bin/sh

test ! -e ./control || exit 1
test -e ./control.main.bash || exit 1
test -e ./control.env.bash || exit 1
test -e ./scriptlets.harness.bash || exit 1
test -e ./scriptlets.library.bash || exit 1

ln -s ./scriptlets.harness.bash ./control || exit 1
ln -s ./scriptlets.library.bash ./control.library.bash || exit 1

if test -e ./bash.elf ; then
	_bash=./bash.elf
else
	_bash=bash
fi

if test "${#}" -eq 0 ; then
	exec "${_bash}" ./control || exit 1
else
	exec "${_bash}" ./control "${@}" || exit 1
fi

exit 1

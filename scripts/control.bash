#!/dev/null

if ! test "${#}" -ge 1 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

if test "${1}" == publish ; then
	test "${#}" -eq 1
	exec bash ./.repositories/mosaic-erlang-dependencies/scriptlets/control.publish.bash
else
	exec ./.outputs/control.sh "${@}"
fi

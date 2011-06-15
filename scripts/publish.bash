#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

exec bash ./.repositories/mosaic-erlang-dependencies/scriptlets/control.publish.bash

#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

exec env "${_epmd_env[@]}" "${_epmd_bin}" "${_epmd_args[@]}"
exit 1

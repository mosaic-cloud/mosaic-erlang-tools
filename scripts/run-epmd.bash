#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

if test "${#_epmd_args[@]}" -eq 0 ; then
	exec env "${_epmd_env[@]}" "${_epmd_bin}"
else
	exec env "${_epmd_env[@]}" "${_epmd_bin}" "${_epmd_args[@]}"
fi

exit 1

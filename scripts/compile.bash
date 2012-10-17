#!/dev/null

if test "${#}" -ge 1 ; then
	_ninja_args+=( "${@}" )
fi

if test "${#_ninja_args[@]}" -eq 0 ; then
	exec env "${_ninja_env[@]}" "${_ninja_bin}"
else
	exec env "${_ninja_env[@]}" "${_ninja_bin}" "${_ninja_args[@]}"
fi

exit 1

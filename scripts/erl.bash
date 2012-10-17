#!/dev/null

if test "${#}" -ge 1 ; then
	_erl_args+=( "${@}" )
fi

if test "${#_erl_args[@]}" -eq 0 ; then
	exec env "${_erl_env[@]}" "${_erl_bin}"
else
	exec env "${_erl_env[@]}" "${_erl_bin}" "${_erl_args[@]}"
fi

exit 1

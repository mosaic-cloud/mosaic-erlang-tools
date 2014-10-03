#!/dev/null
## chunk::d5a458fb8ebc4c9d3e4871341ec4d93a::begin ##

if test "${#}" -ge 1 ; then
	_erl_args+=( "${@}" )
fi

if test "${#_erl_args[@]}" -eq 0 ; then
	exec env "${_erl_env[@]}" "${_erl_bin}"
else
	exec env "${_erl_env[@]}" "${_erl_bin}" "${_erl_args[@]}"
fi

exit 1
## chunk::d5a458fb8ebc4c9d3e4871341ec4d93a::end ##

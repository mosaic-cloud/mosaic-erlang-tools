#!/dev/null
## chunk::fff44f9a0b0a0a3c8ecea7b4f84c6e10::begin ##

if test "${#}" -ge 1 ; then
	_ninja_args+=( "${@}" )
fi

if test "${#_ninja_args[@]}" -eq 0 ; then
	exec env "${_ninja_env[@]}" "${_ninja_bin}"
else
	exec env "${_ninja_env[@]}" "${_ninja_bin}" "${_ninja_args[@]}"
fi

exit 1
## chunk::fff44f9a0b0a0a3c8ecea7b4f84c6e10::end ##

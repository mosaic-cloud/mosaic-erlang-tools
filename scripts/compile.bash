#!/dev/null

if test "${#}" -gt 1 ; then
	_ninja_args+=( "${@}" )
else
	_ninja_args+=( __build__ )
fi

exec env "${_ninja_env[@]}" "${_ninja_bin}" "${_ninja_args[@]}"

exit 1

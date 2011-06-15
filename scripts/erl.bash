#!/dev/null

if test "${#}" -eq 0 ; then
	exec "${_erl}" "${_erl_args[@]}"
else
	exec "${_erl}" "${_erl_args[@]}" "${@}"
fi

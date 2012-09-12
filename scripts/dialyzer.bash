#!/dev/null

if test "${#}" -ge 1 ; then
	_dialyzer_args+=( "${@}" )
fi

if ! test -e "${_dialyzer_plt}" ; then
	env "${_dialyzer_env[@]}" "${_dialyzer_bin}" \
			--build_plt \
			--output_plt "${_dialyzer_plt}" \
			--apps erts kernel stdlib
fi

if test "${#_dialyzer_args[@]}" -eq 0 ; then
	exec env "${_dialyzer_env[@]}" "${_dialyzer_bin}"
else
	exec env "${_dialyzer_env[@]}" "${_dialyzer_bin}" "${_dialyzer_args[@]}"
fi

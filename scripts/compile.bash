#!/dev/null

find -L . -mindepth 1 \( -name '.*' -prune \) -o \( -name 'generate.bash' -print \) \
| while read _generate ; do
	_generated="$( dirname -- "${_generate}" )/.generated"
	if test ! -e "${_generated}" || test "${_generate}" -nt "${_generated}" ; then
		PATH="${_PATH}" "${_generate}"
	fi
done

if \
		test ! -e "${_ninja_file}" -o "${_ninja_file}" -ot "${_vbs_bin}" \
		|| test -n "$( find -L . -mindepth 1 \( -name '.*' -prune \) -o \( -name '*.vbsd' -cnewer "${_ninja_file}" -printf . \) )"
then
	mkdir -p -- "${_outputs}"
	_vbs_args+=(
			--
			generate-ninja-script
			.
			"${_outputs}"
			"${_ninja_file}"
	)
	env "${_vbs_env[@]}" "${_vbs_bin}" "${_vbs_args[@]}"
fi

if test "${#}" -gt 1 ; then
	_ninja_args+=( "${@}" )
else
	_ninja_args+=( __build__ )
fi

exec env "${_ninja_env[@]}" "${_ninja_bin}" "${_ninja_args[@]}"

exit 1

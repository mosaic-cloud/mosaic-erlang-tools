#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

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

exit 0

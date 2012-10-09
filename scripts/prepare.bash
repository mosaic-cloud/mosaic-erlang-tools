#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

if test ! -e "${_outputs}" ; then
	if test -L "${_outputs}" ; then
		_outputs_store="$( readlink -- "${_outputs}" )"
		mkdir -- "${_outputs_store}"
	else
		_outputs_store="${_temporary}/$( basename -- "${_workbench}" )--$( readlink -m -- "${_outputs}" | tr -d '\n' | md5sum -t | tr -d ' \n-' )"
		mkdir -- "${_outputs_store}"
		ln -s -T -- "${_outputs_store}" "${_outputs}"
	fi
fi

find -L . -mindepth 1 \( -name '.*' -prune \) -o \( \( -name 'generate.bash' -o -name 'generate-*.bash' \) -printf '%f\t%p\n' \) \
| sort -t '	' -k 1,1 \
| cut -d '	' -f 2 \
| while read _generate ; do
	_generated="$( dirname -- "${_generate}" )/.generated"
	if test ! -e "${_generated}" || test "${_generate}" -nt "${_generated}" ; then
		echo "[ii] generating \`${_generated}\`..." >&2
		if ! env PATH="${_PATH}" "${_generate}" 2>&1 | sed -u -r -e 's!^.*$![  ] &!g' >&2 ; then
			echo "[ii] failed generating \`${_generated}\`; aborting!" >&2
			rm -Rf -- "$( dirname -- "${_generate}" )/.generated"
			exit 1
		fi
	fi
done

if \
		test ! -e "${_ninja_file}" -o "${_ninja_file}" -ot "${_vbs_bin}" \
		|| test -n "$( find -L . -mindepth 1 \( -name '.*' -prune \) -o \( -name '*.vbsd' -cnewer "${_ninja_file}" -printf . \) )"
then
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

#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

if test ! -e "${_outputs}" ; then
	mkdir -- "${_outputs}"
fi
if test ! -e "${_generated}" ; then
	mkdir -- "${_generated}"
fi


find -L . -mindepth 1 \( -name '.*' -prune \) -o \( \( -name 'generate.bash' -o -name 'generate-*.bash' \) -printf '%f\t%p\n' \) \
| sort -t '	' -k 1,1 \
| cut -d '	' -f 2 \
| while read _generate ; do
	_generate_name="$( basename -- "$( dirname -- "${_generate}" )" )"
	_generate_outputs="${_outputs}/generate--${_generate_name}--$( readlink -e -- "${_generate}" | tr -d '\n' | md5sum -t | tr -d ' \n-' )"
	if test ! -e "${_generate_outputs}/.generated" || test "${_generate}" -nt "${_generate_outputs}/.generated" ; then
		echo "[ii] executing \`${_generate}\`..." >&2
		if test -e "${_generate_outputs}" ; then
			chmod -R u+w -- "${_generate_outputs}"
			rm -Rf -- "${_generate_outputs}"
		fi
		mkdir -- "${_generate_outputs}"
		if ! env "${_generate_env[@]}" _generate_outputs="${_generate_outputs}" "${_generate}" </dev/null 2>&1 | sed -u -r -e 's!^.*$![  ] &!g' >&2 ; then
			echo "[ii] failed executing \`${_generate}\`; aborting!" >&2
			exit 1
		fi
		touch -- "${_generate_outputs}/.generated"
		chmod -R a=rX -- "${_generate_outputs}"
	fi
	if test ! -e "${_generated}/${_generate_name}" ; then
		ln -s -T "${_generate_outputs}" "${_generated}/${_generate_name}"
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

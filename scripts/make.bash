#!/dev/null

find . -mindepth 1 \( -name '.*' -prune \) -o \( -name 'generate.bash' -print \) \
| while read _generate ; do
	_generated="$( dirname -- "${_generate}" )/.generated"
	if test ! -e "${_generated}" || test "${_generate}" -nt "${_generated}" ; then
		echo "[ii] generating miscellaneous files for \`$( dirname -- "${_generate}" )\`..." >&2
		"${_generate}"
	fi
done

if \
		test ! -e "${_ninja_file}" -o "${_ninja_file}" -ot "${_vbs}" \
		|| test -n "$( find -L . -mindepth 1 \( -name '.*' -prune \) -o \( -name '*.vbsd' -cnewer "${_ninja_file}" -printf . \) )"
then
	echo "[ii] generating build script..." >&2
	mkdir -p -- "${_outputs}"
	"${_vbs}" -- generate-ninja-script . "$( basename -- "${_outputs}" )" "${_ninja_file}"
fi
echo "[ii] executing build script..." >&2
if test "${#}" -eq 0 ; then
	exec "${_ninja}" "${_ninja_args[@]}" __build__
else
	exec "${_ninja}" "${_ninja_args[@]}" "${@}"
fi

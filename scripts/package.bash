#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

if test -e "${_outputs}/package" ; then
	chmod -R +w -- "${_outputs}/package"
	rm -R -- "${_outputs}/package"
fi
if test -e "${_outputs}/package.cpio.gz" ; then
	chmod +w -- "${_outputs}/package.cpio.gz"
	rm -- "${_outputs}/package.cpio.gz"
fi

mkdir -- "${_outputs}/package"
mkdir -- "${_outputs}/package/bin"
mkdir -- "${_outputs}/package/lib"

mkdir -- "${_outputs}/package/lib/applications-ez"
mkdir -- "${_outputs}/package/lib/applications-erl"
find "${_outputs}/erlang/applications-ez" -type f -name "*.ez" -print \
| while read _application_ez ; do
	cp -t "${_outputs}/package/lib/applications-ez" -- "${_application_ez}"
	cd -- "${_outputs}/package/lib/applications-erl"
	unzip -q -x -- "${_application_ez}"
done

mkdir -- "${_outputs}/package/lib/applications-elf"
find "${_outputs}/gcc/applications-elf" -type f -name "*.elf" -print \
| while read _application_elf ; do
	cp -t "${_outputs}/package/lib/applications-elf" -- "${_application_elf}"
done

mkdir -- "${_outputs}/package/lib/mosaic-platform-definitions"
find "${_outputs}/package/lib/applications-erl" -maxdepth 1 -type d \
| while read _application_erl ; do
	if test -e "${_application_erl}/priv/mosaic_platform_definitions.term" ; then
		cp -T -- \
				"${_application_erl}/priv/mosaic_platform_definitions.term" \
				"${_outputs}/package/lib/mosaic-platform-definitions/$( basename -- "${_application_erl}" ).term"
	fi
done

mkdir -- "${_outputs}/package/lib/scripts"

cat >"${_outputs}/package/lib/scripts/_do.sh" <<'EOS'
#!/bin/bash

set -e -E -u -o pipefail -o noclobber -o noglob +o braceexpand || exit 1
trap 'printf "[ee] failed: %s\n" "${BASH_COMMAND}" >&2' ERR || exit 1

_self_basename="$( basename -- "${0}" )"
_self_realpath="$( readlink -e -- "${0}" )"
cd "$( dirname -- "${_self_realpath}" )"
cd ../..
_package="$( readlink -e -- . )"
cmp -s -- "${_package}/lib/scripts/_do.sh" "${_self_realpath}"
test -e "${_package}/lib/scripts/${_self_basename}.bash"

test -d "${_package}/env/paths"
_PATH="$(
		find "${_package}/env/paths" -xdev -mindepth 1 -maxdepth 1 -type l -xtype d \
		| sort \
		| while read -r _path ; do
			printf ':%s' "$( readlink -m -- "${_path}" )"
		done
)"
_PATH="${_PATH/:}"
export PATH="${_PATH}"

if test -e "${_package}/env/variables" ; then
	while read -r _path ; do
		_name="$( basename -- "${_path}" )"
		case "${_name}" in
			( @a:* )
				test -L "${_path}"
				_name="${_name/*:}"
				_value="$( readlink -e -- "${_path}" )"
			;;
			( * )
				echo "[ee] invalid variable \`${_path}\`; aborting!"
				exit 1
			;;
		esac
		export -- "${_name}=${_value}"
	done < <(
			find "${_package}/env/variables" -xdev -mindepth 1 \
			| sort
	)
	
fi

_erl_bin="$( PATH="${_PATH}" type -P -- erl || true )"
if test -z "${_erl_bin}" ; then
	echo "[ee] missing \`erl\` (Erlang interpreter) executable in path: \`${_PATH}\`; ignoring!" >&2
	exit 1
fi

_epmd_bin="$( PATH="${_PATH}" type -P -- epmd || true )"
if test -z "${_epmd_bin}" ; then
	echo "[ee] missing \`epmd\` (Erlang Process Mapper Daemon) executable in path: \`${_PATH}\`; ignoring!" >&2
	exit 1
fi

_erl_libs="${_package}/lib/applications-erl"
_erl_cookie="1a839e3e140053d06ad0bc773b2d5771"
_erl_epmd_port="${erlang_epmd_port:-31807}"
_erl_host="localhost"
_erl_args=(
		+Bd +Ww
		+K true
		+A 64
		+hmbs 536870912
		-env ERL_CRASH_DUMP /dev/null
		-env ERL_LIBS "${_erl_libs}"
		-env ERL_EPMD_PORT "${_erl_epmd_port}"
		-env ERL_MAX_PORTS 4096
		-env ERL_FULLSWEEP_AFTER 0
		-env LANG C
)
_erl_env=(
		PATH="${_PATH}"
		ERL_EPMD_PORT="${_erl_epmd_port}"
)

_epmd_port="${_erl_epmd_port}"
_epmd_args=(
		-port "${_epmd_port}"
		-debug
)
_epmd_env=(
		PATH="${_PATH}"
)

if test "${#}" -eq 0 ; then
	. "${_package}/lib/scripts/${_self_basename}.bash"
else
	. "${_package}/lib/scripts/${_self_basename}.bash" "${@}"
fi

echo "[ee] script \`${_self_main}\` should have exited..." >&2
exit 1
EOS

chmod +x -- "${_outputs}/package/lib/scripts/_do.sh"

for _script_name in "${_package_scripts[@]}" ; do
	test -e "${_scripts}/${_script_name}" || continue
	if test -e "${_scripts}/${_script_name}.bash" ; then
		_script_path="${_scripts}/${_script_name}.bash"
	else
		_script_path="$( dirname -- "$( readlink -e -- "${_scripts}/${_script_name}" )" )/${_script_name}.bash"
	fi
	cp -T -- "${_script_path}" "${_outputs}/package/lib/scripts/${_script_name}.bash"
	ln -s -T -- ./_do.sh "${_outputs}/package/lib/scripts/${_script_name}"
	cat >"${_outputs}/package/bin/${_package_name}--${_script_name}" <<EOS
#!/bin/bash
set -e -E -u -o pipefail -o noclobber -o noglob +o braceexpand || exit 1
trap 'printf "[ee] failed: %s\n" "\${BASH_COMMAND}" >&2' ERR || exit 1
if test "\${#}" -eq 0 ; then
	exec "\$( dirname -- "\$( readlink -e -- "\${0}" )" )/../lib/scripts/${_script_name}"
else
	exec "\$( dirname -- "\$( readlink -e -- "\${0}" )" )/../lib/scripts/${_script_name}" "\${@}"
fi
EOS
	chmod +x -- "${_outputs}/package/bin/${_package_name}--${_script_name}"
done

chmod -R a+rX-w,u+w -- "${_outputs}/package"

cd "${_outputs}/package"
find . \
		-xdev -depth \
		\( -type d -o -type l -o -type f \) \
		-print0 \
| cpio -o -H newc -0 --quiet \
| gzip --fast >"${_outputs}/package.cpio.gz"

if test -n "${_artifacts_cache}" ; then
	cp -T -- "${_outputs}/package.cpio.gz" "${_artifacts_cache}/${_package_name}--${_package_version}.cpio.gz"
fi

exit 0

#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

## chunk::d1dfca51fec7f64f5d67609f4980d1b4::begin ##
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
mkdir -- "${_outputs}/package/lib/scripts"
## chunk::d1dfca51fec7f64f5d67609f4980d1b4::end ##

## chunk::bbdfcabc19a4655445078f7f293f5413::begin ##
mkdir -- "${_outputs}/package/lib/applications-ez"
mkdir -- "${_outputs}/package/lib/applications-erl"
find "${_outputs}/erlang/applications-ez" -type f -name "*.ez" -print \
| while read _application_ez ; do
	cp -t "${_outputs}/package/lib/applications-ez" -- "${_application_ez}"
	cd -- "${_outputs}/package/lib/applications-erl"
	unzip -q -x -- "${_application_ez}"
done
## chunk::bbdfcabc19a4655445078f7f293f5413::end ##

## chunk::c1ae3b7a49f4c2c91b75ea89644a66a0::begin ##
mkdir -- "${_outputs}/package/lib/applications-elf"
find "${_outputs}/gcc/applications-elf" -type f -name "*.elf" -print \
| while read _application_elf ; do
	cp -t "${_outputs}/package/lib/applications-elf" -- "${_application_elf}"
done
## chunk::c1ae3b7a49f4c2c91b75ea89644a66a0::end ##

## chunk::4807d5ed37fbd7c950f621f92cd075a3::begin ##
mkdir -- "${_outputs}/package/lib/mosaic-platform-definitions"
find "${_outputs}/package/lib/applications-erl" -maxdepth 1 -type d \
| while read _application_erl ; do
	if test -e "${_application_erl}/priv/mosaic_platform_definitions.term" ; then
		cp -T -- \
				"${_application_erl}/priv/mosaic_platform_definitions.term" \
				"${_outputs}/package/lib/mosaic-platform-definitions/$( basename -- "${_application_erl}" ).term"
	fi
done
## chunk::4807d5ed37fbd7c950f621f92cd075a3::end ##

cat >"${_outputs}/package/lib/scripts/_do.sh" <<'EOS--f4562fe8c5888d3fa382c5a4a98f84a9'
#!/bin/bash
## chunk::f4562fe8c5888d3fa382c5a4a98f84a9::begin ##

## chunk::c766649a978d19b4ca6f7d8d1740eb1b::begin ##
set -e -E -u -o pipefail -o noclobber -o noglob +o braceexpand || exit 1
trap 'printf "[ee] failed: %s\n" "${BASH_COMMAND}" >&2' ERR || exit 1

_self_basename="$( basename -- "${0}" )"
_self_realpath="$( readlink -e -- "${0}" )"
cd -- "$( dirname -- "${_self_realpath}" )"
cd -- ../..
_package="$( readlink -e -- . )"
cmp -s -- "${_package}/lib/scripts/_do.sh" "${_self_realpath}"
test -e "${_package}/lib/scripts/${_self_basename}.bash"
## chunk::c766649a978d19b4ca6f7d8d1740eb1b::end ##

_PATH_extra="${_package}/lib/applications-elf:${_package}/bin"

## chunk::e8e633c1ba85cb854e1f1d77d5f94d94::begin ##
if test -e "${_package}/env/paths" ; then
	test -d "${_package}/env/paths"
	_PATH="$(
			find "${_package}/env/paths" -xdev -mindepth 1 -maxdepth 1 -type l -xtype d \
			| sort \
			| while read -r _path ; do
				printf ':%s' "$( readlink -m -- "${_path}" )"
			done
	)"
	_PATH="${_PATH_extra:-}${_PATH}"
	_PATH="${_PATH/:}"
	export -- PATH="${_PATH}"
else
	_PATH="${_PATH_extra:-}:${PATH:-}"
	_PATH="${_PATH/:}"
	export -- PATH="${_PATH}"
fi

if test -e "${_package}/env/variables" ; then
	test -d "${_package}/env/variables"
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
## chunk::e8e633c1ba85cb854e1f1d77d5f94d94::end ##

## chunk::09a2e65b5bbda62661a905317bea5585::begin ##
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
## chunk::09a2e65b5bbda62661a905317bea5585::end ##

## chunk::1972c9ccaf7f6e27c0c448294e0e9b87::begin ##
if test "${#}" -eq 0 ; then
	. -- "${_package}/lib/scripts/${_self_basename}.bash"
else
	. -- "${_package}/lib/scripts/${_self_basename}.bash" "${@}"
fi

echo "[ee] script \`${_self_main}\` should have exited..." >&2
exit 1
## chunk::1972c9ccaf7f6e27c0c448294e0e9b87::end ##
## chunk::f4562fe8c5888d3fa382c5a4a98f84a9::end ##
EOS--f4562fe8c5888d3fa382c5a4a98f84a9

chmod +x -- "${_outputs}/package/lib/scripts/_do.sh"

for _script_name in "${_package_scripts[@]}" ; do
## chunk::cd272b06265b6e7f94a1bfe0bb8c206f::begin ##
	test -e "${_scripts}/${_script_name}" || continue
	if test -e "${_scripts}/${_script_name}.bash" ; then
		_script_path="${_scripts}/${_script_name}.bash"
	else
		_script_path="$( dirname -- "$( readlink -e -- "${_scripts}/${_script_name}" )" )/${_script_name}.bash"
	fi
	cp -T -- "${_script_path}" "${_outputs}/package/lib/scripts/${_script_name}.bash"
	ln -s -T -- ./_do.sh "${_outputs}/package/lib/scripts/${_script_name}"
	cat >"${_outputs}/package/bin/${_package_name}--${_script_name}" <<EOS--5690bb4114b0428099a9b63f75de8406
#!/bin/bash
## chunk::5690bb4114b0428099a9b63f75de8406::begin ##
set -e -E -u -o pipefail -o noclobber -o noglob +o braceexpand || exit 1
trap 'printf "[ee] failed: %s\n" "\${BASH_COMMAND}" >&2' ERR || exit 1
if test "\${#}" -eq 0 ; then
	exec -- "\$( dirname -- "\$( readlink -e -- "\${0}" )" )/../lib/scripts/${_script_name}" || exit 1
else
	exec -- "\$( dirname -- "\$( readlink -e -- "\${0}" )" )/../lib/scripts/${_script_name}" "\${@}" || exit 1
fi
exit 1
## chunk::5690bb4114b0428099a9b63f75de8406::end ##
EOS--5690bb4114b0428099a9b63f75de8406
	chmod +x -- "${_outputs}/package/bin/${_package_name}--${_script_name}"
## chunk::cd272b06265b6e7f94a1bfe0bb8c206f::end ##
done

## chunk::3b87aa53ffaed5f9c0426a6bbed5704a::begin ##
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
## chunk::3b87aa53ffaed5f9c0426a6bbed5704a::end ##

exit 0

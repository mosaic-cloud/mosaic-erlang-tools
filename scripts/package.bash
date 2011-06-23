#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

_package_name="$( basename -- "$( readlink -e -- . )" )"
_package_version=0.1.alpha
_package_afs=/afs/olympus.volution.ro/people/ciprian/web/data/5e069b1ba84ae3ab9c0eb0d8cbcb0a57

if test -e "${_outputs}/package" ; then
	rm -R "${_outputs}/package"
fi
if test -e "${_outputs}/package.tar.gz" ; then
	rm "${_outputs}/package.tar.gz"
fi
mkdir "${_outputs}/package"
mkdir "${_outputs}/package/bin"
mkdir "${_outputs}/package/lib"

mkdir "${_outputs}/package/lib/applications-ez"
mkdir "${_outputs}/package/lib/applications-erl"
find "${_outputs}/erlang/applications-ez" -type f -name "*.ez" -print \
| while read _application_ez ; do
	cp -t "${_outputs}/package/lib/applications-ez" "${_application_ez}"
	cd "${_outputs}/package/lib/applications-erl"
	unzip -q -x "${_application_ez}"
done

mkdir "${_outputs}/package/lib/applications-elf"
find "${_outputs}/gcc/applications-elf" -type f -name "*.elf" -print \
| while read _application_elf ; do
	cp -t "${_outputs}/package/lib/applications-elf" "${_application_elf}"
done

mkdir "${_outputs}/package/lib/scripts"

cat >"${_outputs}/package/lib/scripts/do.sh" <<'EOS'
#!/bin/bash

set -e -E -u -o pipefail || exit 1

_self_basename="$( basename -- "${0}" )"
_self_realpath="$( readlink -e -- "${0}" )"
cd "$( dirname -- "${_self_realpath}" )"
cd ../..
_package="$( readlink -e -- . )"
cmp -s -- "${_package}/lib/scripts/do.sh" "${_self_realpath}"
test -e "${_package}/lib/scripts/${_self_basename}.bash"

_PATH="${_package}/bin:${_package}/lib/applications-elf:${PATH}"

_erl="$( PATH="${_PATH}" type -P -- erl || true )"
if test -z "${_erl}" ; then
	echo "[ww] missing \`erl\` (Erlang interpreter) executable in path: \`${_PATH}\`; ignoring!" >&2
	_erl=erl
fi

_epmd="$( PATH="${_PATH}" type -P -- epmd || true )"
if test -z "${_epmd}" ; then
	echo "[ww] missing \`epmd\` (Erlang Process Mapper Daemon) executable in path: \`${_PATH}\`; ignoring!" >&2
	_epmd=epmd
fi

_erl_libs="${_package}/lib/applications-erl"
_erl_cookie="1a839e3e140053d06ad0bc773b2d5771"
_erl_epmd_port=31807
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
		PATH="${_package}/lib/applications-elf:${_PATH}"
		ERL_EPMD_PORT="${_erl_epmd_port}"
)

_epmd_port="${_erl_epmd_port}"
_epmd_args=(
	-port "${_epmd_port}"
	-debug
)

if test "${#}" -eq 0 ; then
	. "${_package}/lib/scripts/${_self_basename}.bash"
else
	. "${_package}/lib/scripts/${_self_basename}.bash" "${@}"
fi

echo "[ee] script \`${_self_main}\` should have exited..." >&2
exit 1
EOS

chmod +x -- "${_outputs}/package/lib/scripts/do.sh"

for _script_name in run-node ; do
	cp -T "${_scripts}/${_script_name}.bash" "${_outputs}/package/lib/scripts/${_script_name}.bash"
	ln -s -T ./do.sh "${_outputs}/package/lib/scripts/${_script_name}"
	cat >"${_outputs}/package/bin/${_package_name}--${_script_name}" <<EOS
#!/bin/bash
if test "\${#}" -eq 0 ; then
	exec "\$( dirname -- "\$( readlink -e -- "\${0}" )" )/../lib/scripts/${_script_name}"
else
	exec "\$( dirname -- "\$( readlink -e -- "\${0}" )" )/../lib/scripts/${_script_name}" "\${@}"
fi
EOS
	chmod +x -- "${_outputs}/package/bin/${_package_name}--${_script_name}"
done

cat >"${_outputs}/package/pkg.json" <<EOS
{
	"package" : "${_package_name}",
	"version" : "${_package_version}",
	"maintainer" : "mosaic-developers@lists.info.uvt.ro",
	"directories" : [ "bin", "lib"],
	"depends" : [
		"erlang"
	],
	"description" : "mOSAIC Component: ${_package_name}"
}
EOS

tar -czf "${_outputs}/${_package_name}.tar.gz" -C "${_outputs}/package" .

if test -e "${_package_afs}" ; then
	cp -t "${_package_afs}" "${_outputs}/${_package_name}.tar.gz"
fi

exit 0

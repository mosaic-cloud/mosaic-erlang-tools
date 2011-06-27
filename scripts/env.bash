#!/dev/null

_workbench="$( readlink -e -- . )"
_scripts="${_workbench}/scripts"
_tools="${_workbench}/.tools"
_outputs="${_workbench}/.outputs"
_make=ninja

_PATH="${_tools}/bin:${PATH}"

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

_vbs="$( PATH="${_PATH}" type -P -- vbs || true )"
if test -z "${_vbs}" ; then
	echo "[ww] missing \`vbs\` (Volution Build System tool) executable in path: \`${_PATH}\`; ignoring!" >&2
	_vbs=vbs
fi

_ninja="$( PATH="${_PATH}" which -- ninja 2>/dev/null || true )"
if test -z "${_ninja}" ; then
	echo "[ww] missing \`ninja\` (Ninja build tool) executable in path: \`${_PATH}\`; ignoring!" >&2
	_ninja=ninja
fi

_erl_libs="${_outputs}/erlang/applications"
_erl_cookie="1a839e3e140053d06ad0bc773b2d5771"
_erl_epmd_port=31807
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
		PATH="${_outputs}/gcc/applications-elf:${_PATH}"
		ERL_EPMD_PORT="${_erl_epmd_port}"
)

_epmd_port="${_erl_epmd_port}"
_epmd_args=(
	-port "${_epmd_port}"
	-debug
)

_ninja_file="${_outputs}/.make.ninja"
_ninja_args=(
	-f "${_ninja_file}"
)

_package_name="$( basename -- "$( readlink -e -- . )" )"
_package_version=0.1.alpha
_package_afs=/afs/olympus.volution.ro/people/ciprian/web/data/5e069b1ba84ae3ab9c0eb0d8cbcb0a57

#!/dev/null

_workbench="$( readlink -e -- . )"
_repositories="${_workbench}/.repositories"
_scripts="${_workbench}/scripts"
_tools="${_workbench}/.tools"
_outputs="${_workbench}/.outputs"

_PATH="${_tools}/bin:${PATH}"

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

_vbs_bin="$( PATH="${_PATH}" type -P -- vbs || true )"
if test -z "${_vbs_bin}" ; then
	echo "[ee] missing \`vbs\` (Volution Build System tool) executable in path: \`${_PATH}\`; ignoring!" >&2
	exit 1
fi

_ninja_bin="$( PATH="${_PATH}" type -P -- ninja || true )"
if test -z "${_ninja_bin}" ; then
	echo "[ee] missing \`ninja\` (Ninja build tool) executable in path: \`${_PATH}\`; ignoring!" >&2
	exit 1
fi

_mvn_bin="$( PATH="${_PATH}" type -P -- mvn || true )"
if test -z "${_mvn_bin}" ; then
	echo "[ee] missing \`mvn\` (Java Maven tool) executable in path: \`${_PATH}\`; ignoring!" >&2
	exit 1
fi

_erl_libs="${_outputs}/erlang/applications"
_erl_cookie="1a839e3e140053d06ad0bc773b2d5771"
_erl_epmd_port="${erlang_epmd_port:-31807}"
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
_epmd_env=(
		PATH="${_PATH}"
)

_vbs_args=()
_vbs_env=(
		PATH="${_PATH}"
)

_ninja_file="${_outputs}/.make.ninja"
_ninja_args=(
		-f "${_ninja_file}"
)
_ninja_env=(
		PATH="${_PATH}"
)

_mvn_pkg_pom="${_outputs}/package.mvn/pom.xml"
_mvn_args=(
		--errors --quiet
)
_mvn_env=(
		PATH="${_PATH}"
)

_package_name="$( basename -- "$( readlink -e -- . )" )"
_package_scripts=( run-node run-component run-epmd erl )
_package_version="${mosaic_distribution_version:-0.2.0_mosaic_dev}"
_package_cook="${mosaic_distribution_cook:-cook@agent1.builder.mosaic.ieat.ro}"

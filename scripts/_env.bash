#!/dev/null

set -e -E -u -o pipefail -o noclobber -o noglob +o braceexpand || exit 1
trap 'printf "[ee] failed: %s\n" "${BASH_COMMAND}" >&2' ERR || exit 1
export -n BASH_ENV

_workbench="$( readlink -e -- . )"
_scripts="${_workbench}/scripts"
_tools="${pallur_tools:-${_workbench}/.tools}"
_temporary="${pallur_temporary:-${pallur_TMPDIR:-${TMPDIR:-/tmp}}}"
_outputs="${_temporary}/$( basename -- "${_workbench}" )--outputs--$( readlink -e -- "${_workbench}" | tr -d '\n' | md5sum -t | tr -d ' \n-' )"
_generated="${_outputs}/generated"

_PATH="${pallur_PATH:-${_tools}/bin:${PATH}}"
_HOME="${pallur_HOME:-${HOME}}"
_TMPDIR="${pallur_TMPDIR:-${TMPDIR:-${_temporary}}}"

if test -n "${pallur_pkg_erlang:-}" ; then
	_erl_bin="${pallur_pkg_erlang}/bin/erl"
elif test -e "${_tools}/pkg/erlang" ; then
	_erl_bin="${_tools}/pkg/erlang/bin/erl"
else
	_erl_bin="$( PATH="${_PATH}" type -P -- erl || true )"
fi
if test -z "${_erl_bin}" ; then
	echo "[ee] missing \`erl\` (Erlang interpreter) executable in path: \`${_PATH}\`; ignoring!" >&2
	_erl_bin=false
fi

if test -n "${pallur_pkg_erlang:-}" ; then
	_epmd_bin="${pallur_pkg_erlang}/bin/epmd"
elif test -e "${_tools}/pkg/erlang" ; then
	_epmd_bin="${_tools}/pkg/erlang/bin/epmd"
else
	_epmd_bin="$( PATH="${_PATH}" type -P -- epmd || true )"
fi
if test -z "${_epmd_bin}" ; then
	echo "[ee] missing \`epmd\` (Erlang Process Mapper Daemon) executable in path: \`${_PATH}\`; ignoring!" >&2
	_epmd_bin=false
fi

if test -n "${pallur_pkg_erlang:-}" ; then
	_dialyzer_bin="${pallur_pkg_erlang}/bin/dialyzer"
elif test -e "${_tools}/pkg/erlang" ; then
	_dialyzer_bin="${_tools}/pkg/erlang/bin/dialyzer"
else
	_dialyzer_bin="$( PATH="${_PATH}" type -P -- dialyzer || true )"
fi
if test -z "${_dialyzer_bin}" ; then
	echo "[ee] missing \`dialyzer\` (Erlang Discrepancy Analyzer) executable in path: \`${_PATH}\`; ignoring!" >&2
	_dialyzer_bin=false
fi

_vbs_bin="$( PATH="${_PATH}" type -P -- vbs || true )"
if test -z "${_vbs_bin}" ; then
	echo "[ee] missing \`vbs\` (Volution Build System tool) executable in path: \`${_PATH}\`; ignoring!" >&2
	_vbs_bin=false
fi

_ninja_bin="$( PATH="${_PATH}" type -P -- ninja || true )"
if test -z "${_ninja_bin}" ; then
	echo "[ee] missing \`ninja\` (Ninja build tool) executable in path: \`${_PATH}\`; ignoring!" >&2
	_ninja_bin=false
fi

_generic_env=(
		PATH="${_PATH}"
		HOME="${_HOME}"
		TMPDIR="${_TMPDIR}"
)

if test -n "${pallur_pkg_erlang:-}" ; then _generic_env+=( pallur_pkg_erlang="${pallur_pkg_erlang}" ) ;
elif test -e "${_tools}/pkg/erlang" ; then _generic_env+=( pallur_pkg_erlang="${_tools}/pkg/erlang" ) ; fi

if test -n "${pallur_pkg_zeromq:-}" ; then _generic_env+=( pallur_pkg_zeromq="${pallur_pkg_zeromq}" ) ;
elif test -e "${_tools}/pkg/zeromq" ; then _generic_env+=( pallur_pkg_zeromq="${_tools}/pkg/zeromq" ) ; fi

if test -n "${pallur_pkg_jansson:-}" ; then _generic_env+=( pallur_pkg_jansson="${pallur_pkg_jansson}" ) ;
elif test -e "${_tools}/pkg/jansson" ; then _generic_env+=( pallur_pkg_jansson="${_tools}/pkg/jansson" ) ; fi

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
		"${_generic_env[@]}"
		PATH="${_outputs}/gcc/applications-elf:${_PATH}"
		ERL_EPMD_PORT="${_erl_epmd_port}"
)

_epmd_port="${_erl_epmd_port}"
_epmd_args=(
		-port "${_epmd_port}"
		-debug
)
_epmd_env=(
		"${_generic_env[@]}"
)

_dialyzer_plt="${_outputs}/erlang/applications.plt"
_dialyzer_args=(
		--plt "${_dialyzer_plt}"
		-Wunmatched_returns
		-Werror_handling
		-Wrace_conditions
		# -Wbehaviours
		-Wunderspecs
		-Woverspecs
		-Wspecdiffs
)
_dialyzer_env=(
		"${_generic_env[@]}"
		ERL_LIBS="${_erl_libs}"
)

_vbs_args=()
_vbs_env=(
		"${_generic_env[@]}"
		_workbench="${_workbench}"
		_scripts="${_scripts}"
		_tools="${_tools}"
		_temporary="${_temporary}"
		_outputs="${_outputs}"
		_generated="${_generated}"
)

_ninja_file="${_outputs}/.make.ninja"
_ninja_args=(
		-f "${_ninja_file}"
)
_ninja_env=(
		"${_generic_env[@]}"
)

_generate_env=(
		"${_generic_env[@]}"
		_workbench="${_workbench}"
		_scripts="${_scripts}"
		_tools="${_tools}"
		_temporary="${_temporary}"
		_outputs="${_outputs}"
		_generated="${_generated}"
)

_package_name="$( basename -- "$( readlink -e -- . )" )"
_package_version="${pallur_distribution_version:-0.7.0_dev}"
_package_scripts=( run-node run-service run-component run-tests run-epmd erl )
_artifacts_cache="${pallur_artifacts:-}"

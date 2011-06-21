#!/dev/null


test "${_harness_fingerprint:-??}" == b829e0d2a9fa7b9e5edbe03821032e42 || { echo "[ee] incompatible (or missing) harness; aborting!" >&2 ; exit 1 ; }
test "${_library_fingerprint:-??}" == 36dcfdc332deccb97efc6a1fc14c1cbc || { echo "[ee] incompatible (or missing) library; aborting!" >&2 ; exit 1 ; }
test "${1:-??}" == '--'
shift


if ! test "${#}" -ge 2 ; then
	_abort main "usage: control <action> <deployment-path> <arguments>*"
fi

_action="${1}"
_deployment_path="${2}"
shift 2

if test "${_deployment_path:0:1}" != "/" ; then
	_abort main "usage: <deployment-path> must be an absolute path"
fi


__configure () {
	test "${#}" -eq 0
	_deployment_bundles_path="${_deployment_path}/bundles"
	_deployment_erlang_path="${_deployment_path}/erlang"
	_deployment_data_path="${_deployment_path}/data"
	_erl_path=''
	_erl_args=(
			+Bd +Ww
			+K true
			+A 64
			-env ERL_CRASH_DUMP /dev/null
			-env ERL_LIBS "${_deployment_erlang_path}/lib"
			-env ERL_MAX_PORTS 4096
			-env ERL_FULLSWEEP_AFTER 0
			-env LANG C
	)
	_source ./control.env.bash
	return 0
}


__fetch_bundles () {
	_set_failure_message 'failed fetching bundles'
	test "${#}" -eq 0
	local __bundle_name='' __bundle_path='' __bundle_url=''
	for __bundle_name in "${_ez_bundle_names[@]}" ; do
		__bundle_path="${_deployment_bundles_path}/${__bundle_name}.ez"
		__bundle_url="${_bundles_base_url}/${__bundle_name}.ez"
		if test -e "${__bundle_path}" ; then
			_trace info main "bundle already exists: \`${__bundle_path}\`; re-fetching!"
		fi
		_curl_fetch_file "${__bundle_path}" "${__bundle_url}"
	done
	_unset_failure_message
	return 0
}


__deploy_erlang_applications () {
	_set_failure_message 'failed deploying erlang applications'
	test "${#}" -eq 0
	if test -e "${_deployment_erlang_path}/lib" ; then
		_trace warn main "erlang applications already deployed; re-deploying!"
		_run_sync rm -Rf -- "${_deployment_erlang_path}/lib"
	fi
	_create_folder "${_deployment_erlang_path}/lib"
	local __bundle_name='' __bundle_path=''
	for __bundle_name in "${_ez_bundle_names[@]}" ; do
		__bundle_path="${_deployment_bundles_path}/${__bundle_name}.ez"
		_extract_archive "${_deployment_erlang_path}/lib" "${__bundle_path}" zip
	done
	_unset_failure_message
	return 0
}


_deploy () {
	_set_failure_message 'failed deploying'
	test "${#}" -eq 0
	__configure
	_create_folder "${_deployment_path}"
	_create_folder "${_deployment_bundles_path}"
	_create_folder "${_deployment_erlang_path}"
	_create_folder "${_deployment_data_path}"
	__fetch_bundles
	__deploy_erlang_applications
	_unset_failure_message
	return 0
}


_run () {
	_set_failure_message 'failed running'
	__configure
	if ! test -e "${_deployment_path}" -a -e "${_deployment_erlang_path}" -a -e "${_deployment_data_path}" ; then
		_abort main "nothing deployed at the specified path: \`${_deployment_path}\`"
	fi
	if test -z "${_erl_path}" ; then
		_resolve_executable _erl_path erl
	fi
	cd -- "${_deployment_path}"
	_run_exec "${_erl_path}" "${_erl_args[@]}"
	_abort main "fallen through..."
	_unset_failure_message
}


case "${_action}" in
	( deploy )
		if ! test "${#}" -eq 0 ; then
			_abort main "usage: control deploy <deployment-path>"
		fi
		_deploy
		_exit 0
	;;
	( run )
		if ! test "${#}" -eq 0 ; then
			_abort main "usage: control run <deployment-path>"
		fi
		_run
	;;
	( * )
		_abort main "unknown action: \`${_action}\`"
	;;
esac


_abort main "fallen through..."

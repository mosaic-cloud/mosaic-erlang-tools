#!/dev/null


test "${_harness_fingerprint:-??}" == b829e0d2a9fa7b9e5edbe03821032e42 || { echo "[ee] incompatible (or missing) harness; aborting!" >&2 ; exit 1 ; }
test "${_library_fingerprint:-??}" == '??' || { echo "[ee] incompatible library; aborting!" >&2 ; exit 1 ; }
test "${1:-??}" == '--'
shift
test "${#}" -eq 0

_library_fingerprint=36dcfdc332deccb97efc6a1fc14c1cbc


___s3cmd_access_key=''
___s3cmd_secret_key=''
___s3cmd_location=''
___s3cmd_walrus_host=''
___s3cmd_walrus_prefix=''
___s3cmd_configuration_path=''

___s3cmd_exec_path=''
___curl_exec_path=''
___tar_exec_path=''
___unzip_exec_path=''
___gunzip_exec_path=''
___bunzip2_exec_path=''


_s3cmd_configure () {
	test "${#}" -ge 1
	_set_failure_message 'failed configuring s3cmd'
	local ___local_option="${1}"
	local ___local_module=s3cmd
	shift
	case "${___local_option}" in
		( access-key )
			test "${#}" -eq 1
			_trace debug "${___local_module}" "configuring access key..."
			if test -n "${___s3cmd_access_key}" ; then
				_trace warn "${___local_module}" "access key was already configured; overriding!"
			fi
			___s3cmd_access_key="${1}"
		;;
		( secret-key )
			test "${#}" -eq 1
			_trace debug "${___local_module}" "configuring secret key..."
			if test -n "${___s3cmd_secret_key}" ; then
				_trace warn "${___local_module}" "secret key was already configured; overriding!"
			fi
			___s3cmd_secret_key="${1}"
		;;
		( location )
			test "${#}" -eq 1
			_trace debug "${___local_module}" "configuring location..."
			if test -n "${___s3cmd_location}" ; then
				_trace warn "${___local_module}" "location was already configured; overriding!"
			fi
			___s3cmd_location="${1}"
		;;
		( walrus )
			test "${#}" -eq 2
			_trace debug "${___local_module}" "configuring walrus..."
			if test "${___s3cmd_location}" == '__walrus__' ; then
				_trace warn "${___local_module}" "walrus was already configured; overriding!"
			elif test -n "${___s3cmd_location}" ; then
				_trace warn "${___local_module}" "location was already configured and was not walrus; overriding!"
			fi
			___s3cmd_location='__walrus__'
			___s3cmd_walrus_host="${1}"
			___s3cmd_walrus_prefix="${2}"
		;;
		( reset )
			test "${#}" -eq 0
			_trace debug "${___local_module}" "resetting configuration..."
			___s3cmd_access_key=''
			___s3cmd_secret_key=''
			___s3cmd_location=''
			___s3cmd_walrus_host=''
			___s3cmd_walrus_prefix=''
			___s3cmd_configuration_path=''
		;;
		( commit )
			test "${#}" -eq 0
			_trace debug "${___local_module}" "commiting configuration..."
			if test -z "${___s3cmd_access_key}" -o -z "${___s3cmd_secret_key}" -o -z "${___s3cmd_location}" ; then
				_trace error "${___local_module}" "undefined configuration options, either: access-key, secret-key, location; aborting!"
				return 1
			fi
			if test -n "${___s3cmd_configuration_path}" ; then
				_trace warn "${___local_module}" "configuration was already commited: \`${___s3cmd_configuration_path}\`; overriding!"
			fi
			_tmp_create_file ___s3cmd_configuration_path s3cmd .cfg
			{
				echo "[default]"
				echo "access_key = ${___s3cmd_access_key}"
				echo "secret_key = ${___s3cmd_secret_key}"
				if test "${___s3cmd_location}" == '__walrus__' ; then
					echo "host_base = ${___s3cmd_walrus_host}"
					echo "service_path = ${___s3cmd_walrus_prefix}"
				elif test -n "${___s3cmd_location}" ; then
					echo "bucket_location = ${___s3cmd_location}"
				fi
			} >|"${___s3cmd_configuration_path}"
			_trace debug "${___local_module}" "commited configuration: \`${___s3cmd_configuration_path}\`"
		;;
		( * )
			_trace error "${___local_module}" "unknown configuration option: \`${___local_option}\`; aborting!"
			return 1
		;;
	esac
	_unset_failure_message
	return 0
}


_s3cmd_fetch_file () {
	test "${#}" -eq 2
	local ___local_target_file="${1}"
	local ___local_source_url="${2}"
	local ___local_module=s3cmd
	_set_failure_message "failed fetching S3 file \`${___local_target_file}\` <- \`${___local_source_url}\`"
	if test -z "${___s3cmd_exec_path}" ; then
		_resolve_executable ___s3cmd_exec_path s3cmd
	fi
	_trace info "${___local_module}" "fetching S3 file: \`${___local_target_file}\` <- \`${___local_source_url}\`..."
	if test -z "${___s3cmd_configuration_path}" ; then
		_trace error "${___local_module}" "configuration was not commited; aborting!"
		return 1
	elif ! test -f "${___s3cmd_configuration_path}" ; then
		_trace error "${___local_module}" "configuration was already commited but the file does not exist (or has an unknown type): \`${___s3cmd_configuration_path}\`; aborting!"
		return 1
	fi
	local ___local_target_tmp_file=''
	while true ; do
		___local_target_tmp_file="${1}.tmp_${_harness_pid}_${RANDOM}${RANDOM}"
		if ! test -e "${___local_target_tmp_file}" ; then
			break
		fi
	done
	if ! ___write_file_before_hook "${___local_module}" "${___local_target_file}" "${___local_target_tmp_file}" ; then
		return 1
	fi
	if ! _run_sync "${___s3cmd_exec_path}" --config "${___s3cmd_configuration_path}" --no-progress get "${___local_source_url}" "${___local_target_tmp_file}"
	then
		_trace error "${___local_module}" "failed fetching S3 file: \`${___local_target_file}\` <- \`${___local_source_url}\`; aborting!"
		return 1
	else
		if ! ___write_file_after_hook "${___local_module}" "${___local_target_file}" "${___local_target_tmp_file}" ; then
			return 1
		fi
	fi
	_unset_failure_message
	return 0
}


_ec2_fetch_user_data () {
	test "${#}" -eq 1
	local ___local_target_file="${1}"
	local ___local_source_url='http://169.254.169.254/2009-04-04/user-data'
	local ___local_module=ec2
	_set_failure_message "failed fetching EC2 user data file \`${___local_target_file}\` <- \`${___local_source_url}\`"
	if test -z "${___curl_exec_path}" ; then
		_resolve_executable ___curl_exec_path curl
	fi
	_trace info "${___local_module}" "fetching EC2 user data file: \`${___local_target_file}\` <- \`${___local_source_url}\`..."
	local ___local_target_tmp_file=''
	while true ; do
		___local_target_tmp_file="${1}.tmp_${_harness_pid}_${RANDOM}${RANDOM}"
		if ! test -e "${___local_target_tmp_file}" ; then
			break
		fi
	done
	if ! ___write_file_before_hook "${___local_module}" "${___local_target_file}" "${___local_target_tmp_file}" ; then
		return 1
	fi
	if ! touch -- "${___local_target_tmp_file}" ; then
		_trace error "${___local_module}" "failed creating temporary file: \`${___local_target_tmp_file}\`; aborting!"
		return 1
	fi
	if ! _run_sync "${___curl_exec_path}" -s -S \
			-w 'File %{url_effective} saved as '"'${___local_target_tmp_file//%/%%}'"' (%{size_download} bytes in %{time_total} seconds, %{speed_download} B/s)\n' \
			-o "${___local_target_tmp_file}" -- "${___local_source_url}"
	then
		_trace error "${___local_module}" "failed fetching EC2 user data file: \`${___local_target_file}\` <- \`${___local_source_url}\`; aborting!"
		return 1
	else
		if ! ___write_file_after_hook "${___local_module}" "${___local_target_file}" "${___local_target_tmp_file}" ; then
			return 1
		fi
	fi
	_unset_failure_message
	return 0
}


_curl_fetch_file () {
	test "${#}" -eq 2
	local ___local_target_file="${1}"
	local ___local_source_url="${2}"
	local ___local_module=curl
	_set_failure_message "failed fetching file \`${___local_target_file}\` <- \`${___local_source_url}\`"
	if test -z "${___curl_exec_path}" ; then
		_resolve_executable ___curl_exec_path curl
	fi
	_trace info "${___local_module}" "fetching file: \`${___local_target_file}\` <- \`${___local_source_url}\`..."
	local ___local_target_tmp_file=''
	while true ; do
		___local_target_tmp_file="${1}.tmp_${_harness_pid}_${RANDOM}${RANDOM}"
		if ! test -e "${___local_target_tmp_file}" ; then
			break
		fi
	done
	if ! ___write_file_before_hook curl "${___local_target_file}" "${___local_target_tmp_file}" ; then
		return 1
	fi
	if ! touch -- "${___local_target_tmp_file}" ; then
		_trace error "${___local_module}" "failed creating temporary file: \`${___local_target_tmp_file}\`; aborting!"
		return 1
	fi
	if ! _run_sync "${___curl_exec_path}" -s -S \
			-w 'File %{url_effective} saved as '"'${___local_target_tmp_file//%/%%}'"' (%{size_download} bytes in %{time_total} seconds, %{speed_download} B/s)\n' \
			-o "${___local_target_tmp_file}" -- "${___local_source_url}"
	then
		_trace error "${___local_module}" "failed fetching file: \`${___local_target_file}\` <- \`${___local_source_url}\`; aborting!"
		return 1
	else
		if ! ___write_file_after_hook curl "${___local_target_file}" "${___local_target_tmp_file}" ; then
			return 1
		fi
	fi
	_unset_failure_message
	return 0
}


_create_file_inline () {
	test "${#}" -eq 2
	local ___local_target_file="${1}"
	local ___local_target_data="${2}"
	local ___local_module=library
	_set_failure_message "failed creating inline file \`${___local_target_file}\`"
	_trace info "${___local_module}" "creating inline file: \`${___local_target_file}\`..."
	local ___local_target_tmp_file=''
	while true ; do
		___local_target_tmp_file="${1}.tmp_${_harness_pid}_${RANDOM}${RANDOM}"
		if ! test -e "${___local_target_tmp_file}" ; then
			break
		fi
	done
	if ! ___write_file_before_hook "${___local_module}" "${___local_target_file}" "${___local_target_tmp_file}" ; then
		return 1
	fi
	if ! echo -E -n "${___local_target_data}" >"${___local_target_tmp_file}" ; then
		_trace error "${___local_module}" "failed creating inline file: \`${___local_target_file}\`; aborting!"
		return 1
	else
		if ! ___write_file_after_hook "${___local_module}" "${___local_target_file}" "${___local_target_tmp_file}" ; then
			return 1
		fi
	fi
	_unset_failure_message
	return 0
}


_create_folder () {
	test "${#}" -eq 1
	local ___local_target_folder="${1}"
	local ___local_module=library
	_set_failure_message "failed creating folder \`${___local_target_folder}\`"
	_trace info "${___local_module}" "creating folder: \`${___local_target_folder}\`..."
	if ! test -e "${___local_target_folder}" ; then
		mkdir -p -- "${___local_target_folder}"
	elif test -f "${___local_target_folder}" ; then
		_trace error "${___local_module}" "target folder path already exists but is a file: \`${___local_target_folder}\`; aborting!"
		return 1
	elif ! test -d "${___local_target_folder}" ; then
		_trace error "${___local_module}" "target folder path already exists but has an unknown type: \`${___local_target_folder}\`; aborting!"
		return 1
	else
		_trace warn "${___local_module}" "target folder already exists: \`${___local_target_folder}\`; keeping!"
	fi
	_unset_failure_message
	return 0
}


_extract_archive () {
	test "${#}" -eq 3
	local ___local_target_folder="${1}"
	local ___local_archive_file="${2}"
	local ___local_archive_type="${3}"
	local ___local_module=extract
	_set_failure_message "failed extracting archive \`${___local_target_folder}\` <- \`${___local_archive_file}\`"
	_trace info "${___local_module}" "extracting archive: \`${___local_target_folder}\` <- \`${___local_archive_file}\`..."
	if ! [[ "${___local_archive_type}" =~ ^tar|tar\.gz|tar\.bz2|zip$ ]] ; then
		_trace error "${___local_module}" "invalid archive type: \`${___local_archive_type}\`; aborting!"
		return 1
	fi
	if ! ___check_source_file "${___local_module}" "${___local_archive_file}" ; then
		return 1
	fi
	if ! ___check_target_folder "${___local_module}" "${___local_target_folder}" ; then
		return 1
	fi
	if test "$( ls -AU1 -- "${___local_target_folder}" | wc -l )" -gt 0 ; then
		_trace warn "${___local_module}" "target folder already exists but is not empty: \`${___local_target_folder}\`; overwriting existing files!"
	fi
	local ___local_command_arguments=() ___local_command=''
	case "${___local_archive_type}" in
		( tar )
			___local_command=tar
			___local_command_arguments=( -xf "${___local_archive_file}" --no-same-owner --no-same-permissions -C "${___local_target_folder}" )
		;;
		( tar.gz )
			___local_command=tar
			___local_command_arguments=( -xzf "${___local_archive_file}" --no-same-owner --no-same-permissions -C "${___local_target_folder}" )
		;;
		( tar.bz2 )
			___local_command=tar
			___local_command_arguments=( -xjf "${___local_archive_file}" --no-same-owner --no-same-permissions -C "${___local_target_folder}" )
		;;
		( zip )
			___local_command=unzip
			___local_command_arguments=( -q -o "${___local_archive_file}" -d "${___local_target_folder}" )
		;;
		( * )
			_abort "${___local_module}" "unexpected code branch; aborting!"
		;;
	esac
	case "${___local_command}" in
		( tar )
			if test -z "${___tar_exec_path}" ; then
				_resolve_executable ___tar_exec_path tar
			fi
			___local_command="${___tar_exec_path:-tar}"
		;;
		( unzip )
			if test -z "${___unzip_exec_path}" ; then
				_resolve_executable ___unzip_exec_path unzip
			fi
			___local_command="${___unzip_exec_path:-unzip}"
		;;
		( * )
		;;
	esac
	if ! _run_sync "${___local_command}" "${___local_command_arguments[@]}" ; then
		_trace error "${___local_module}" "failed extracting archive: \`${___local_target_folder}\` <- \`${___local_archive_file}\`; aborting!"
		return 1
	fi
	_unset_failure_message
	return 0
}


_uncompress_file () {
	test "${#}" -eq 3
	local ___local_target_file="${1}"
	local ___local_archive_file="${2}"
	local ___local_archive_type="${3}"
	local ___local_module=extract
	_set_failure_message "failed extracting archive \`${___local_target_file}\` <- \`${___local_archive_file}\`"
	_trace info "${___local_module}" "extracting archive: \`${___local_target_file}\` <- \`${___local_archive_file}\`..."
	if ! [[ "${___local_archive_type}" =~ ^gz|bz2$ ]] ; then
		_trace error "${___local_module}" "invalid archive type: \`${___local_archive_type}\`; aborting!"
		return 1
	fi
	if ! ___check_source_file "${___local_module}" "${___local_archive_file}" ; then
		return 1
	fi
	local ___local_target_tmp_file=''
	while true ; do
		___local_target_tmp_file="${1}.tmp_${_harness_pid}_${RANDOM}${RANDOM}"
		if ! test -e "${___local_target_tmp_file}" ; then
			break
		fi
	done
	if ! ___write_file_before_hook "${___local_module}" "${___local_target_file}" "${___local_target_tmp_file}" ; then
		return 1
	fi
	if ! touch -- "${___local_target_tmp_file}" ; then
		_trace error "${___local_module}" "failed creating temporary file: \`${___local_target_tmp_file}\`; aborting!"
		return 1
	fi
	local ___local_command=()
	case "${___local_archive_type}" in
		( gz )
			if test -z "${___gunzip_exec_path}" ; then
				_resolve_executable ___gunzip_exec_path gz
			fi
			___local_command="${___gunzip_exec_path}"
		;;
		( bz2 )
			if test -z "${___bunzip2_exec_path}" ; then
				_resolve_executable ___bunzip2_exec_path bunzip2
			fi
			___local_command="${___bunzip2_exec_path}"
		;;
		( * )
			_abort library "unexpected code branch; aborting!"
		;;
	esac
	if ! _run_sync_io "${___local_archive_file}" "${___local_target_tmp_file}" "${___local_command}"
	then
		_trace error "${___local_module}" "failed extracting archive: \`${___local_target_file}\` <- \`${___local_archive_file}\`; aborting!"
		return 1
	else
		if ! ___write_file_after_hook "${___local_module}" "${___local_target_file}" "${___local_target_tmp_file}" ; then
			return 1
		fi
	fi
	_unset_failure_message
	return 0
}


___write_file_before_hook () {
	test "${#}" -eq 3
	local ___local_module="${1}"
	local ___local_target_file="${2}"
	local ___local_target_folder="$( dirname -- "${___local_target_file}" )"
	local ___local_target_tmp_file="${3}"
	if ! ___check_target_folder "${___local_module}" "${___local_target_folder}" ; then
		return 1
	fi
	if ! ___check_target_file "${___local_module}" "${___local_target_file}" ; then
		return 1
	fi
	! test -e "${___local_target_tmp_file}"
	_tmp_enqueue "${___local_target_tmp_file}"
	return 0
}


___write_file_after_hook () {
	test "${#}" -eq 3
	local ___local_module="${1}"
	local ___local_target_file="${2}"
	local ___local_target_tmp_file="${3}"
	test -f "${___local_target_tmp_file}"
	if ! mv -T -- "${___local_target_tmp_file}" "${___local_target_file}" ; then
		_trace error "${___local_module}" "failed renaming from temporary to target file: \`${___local_target_file}\` <- \`${___local_target_tmp_file}\`; aborting!"
		return 1
	fi
	return 0
}


___check_target_folder () {
	test "${#}" -eq 2
	local ___local_module="${1}"
	local ___local_target_folder="${2}"
	_trace debug "${___local_module}" "checking target folder path: \`${___local_target_folder}\`..."
	if ! test -e "${___local_target_folder}" ; then
		_trace warn "${___local_module}" "target folder does not exist: \`${___local_target_folder}\`; creating!"
		mkdir -p -- "${___local_target_folder}"
	elif test -f "${___local_target_folder}" ; then
		_trace error "${___local_module}" "target folder path already exists but is a file: \`${___local_target_folder}\`; aborting!"
		return 1
	elif ! test -d "${___local_target_folder}" ; then
		_trace error "${___local_module}" "target folder path already exists but has an unknown type: \`${___local_target_folder}\`; aborting!"
		return 1
	fi
	return 0
}


___check_target_file () {
	test "${#}" -eq 2
	local ___local_module="${1}"
	local ___local_target_file="${2}"
	_trace debug "${___local_module}" "checking target file path: \`${___local_target_file}\`..."
	if test -f "${___local_target_file}" ; then
		_trace warn "${___local_module}" "target file already exists: \`${___local_target_file}\`; overwriting!"
	elif test -d "${___local_target_file}" ; then
		_trace error "${___local_module}" "target file path already exists but is a folder: \`${___local_target_file}\`; aborting!"
		return 1
	elif test -e "${___local_target_file}" ; then
		_trace error "${___local_module}" "target file path already exists but has an unknown type: \`${___local_target_file}\`; aborting!"
		return 1
	fi
	return 0
}


___check_source_file () {
	test "${#}" -eq 2
	local ___local_module="${1}"
	local ___local_source_file="${2}"
	_trace debug "${___local_module}" "checking source file path: \`${___local_source_file}\`..."
	if ! test -e "${___local_source_file}" ; then
		_trace error "${___local_module}" "source file does not exist: \`${___local_source_file}\`; aborting!"
		return 1
	elif test -d "${___local_source_file}" ; then
		_trace error "${___local_module}" "source file path already exists but is a folder: \`${___local_source_file}\`; aborting!"
		return 1
	elif ! test -f "${___local_source_file}" ; then
		_trace error "${___local_module}" "source file path alreay exists but has an unknown type: \`${___local_source_file}\`; aborting!"
		return 1
	fi
	return 0
}

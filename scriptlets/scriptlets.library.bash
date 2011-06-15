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


_s3cmd_configure () {
	test "${#}" -ge 1
	_set_failure_message 'failed configuring s3cmd'
	local ___local_option="${1}"
	shift
	case "${___local_option}" in
		( access-key )
			test "${#}" -eq 1
			_trace debug s3cmd "configuring access key..."
			if test -n "${___s3cmd_access_key}" ; then
				_trace warn s3cmd "access key was already configured; overriding!"
			fi
			___s3cmd_access_key="${1}"
		;;
		( secret-key )
			test "${#}" -eq 1
			_trace debug s3cmd "configuring secret key..."
			if test -n "${___s3cmd_secret_key}" ; then
				_trace warn s3cmd "secret key was already configured; overriding!"
			fi
			___s3cmd_secret_key="${1}"
		;;
		( location )
			test "${#}" -eq 1
			_trace debug s3cmd "configuring location..."
			if test -n "${___s3cmd_location}" ; then
				_trace warn s3cmd "location was already configured; overriding!"
			fi
			___s3cmd_location="${1}"
		;;
		( walrus )
			test "${#}" -eq 2
			_trace debug s3cmd "configuring walrus..."
			if test "${___s3cmd_location}" == '__walrus__' ; then
				_trace warn s3cmd "walrus was already configured; overriding!"
			elif test -n "${___s3cmd_location}" ; then
				_trace warn s3cmd "location was already configured and was not walrus; overriding!"
			fi
			___s3cmd_location='__walrus__'
			___s3cmd_walrus_host="${1}"
			___s3cmd_walrus_prefix="${2}"
		;;
		( reset )
			test "${#}" -eq 0
			_trace debug s3cmd "resetting configuration..."
			___s3cmd_access_key=''
			___s3cmd_secret_key=''
			___s3cmd_location=''
			___s3cmd_walrus_host=''
			___s3cmd_walrus_prefix=''
			___s3cmd_configuration_path=''
		;;
		( commit )
			test "${#}" -eq 0
			_trace debug s3cmd "commiting configuration..."
			if test -z "${___s3cmd_access_key}" -o -z "${___s3cmd_secret_key}" -o -z "${___s3cmd_location}" ; then
				_trace error s3cmd "undefined configuration options, either: access-key, secret-key, location; aborting!"
				return 1
			fi
			if test -n "${___s3cmd_configuration_path}" ; then
				_trace warn s3cmd "configuration was already commited: \`${___s3cmd_configuration_path}\`; overriding!"
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
			_trace debug s3cmd "commited configuration: \`${___s3cmd_configuration_path}\`"
		;;
		( * )
			_trace error s3cmd "unknown configuration option: \`${___local_option}\`; aborting!"
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
	_set_failure_message "failed fetching S3 file \`${___local_target_file}\` <- \`${___local_source_url}\`"
	_trace info s3cmd "fetching S3 file: \`${___local_target_file}\` <- \`${___local_source_url}\`..."
	if test -z "${___s3cmd_configuration_path}" ; then
		_trace error s3cmd "configuration was not commited; aborting!"
		return 1
	elif ! test -f "${___s3cmd_configuration_path}" ; then
		_trace error s3cmd "configuration was already commited but the file does not exist (or has an unknown type): \`${___s3cmd_configuration_path}\`; aborting!"
		return 1
	fi
	local ___local_target_tmp_file=''
	while true ; do
		___local_target_tmp_file="${1}.tmp_${_harness_pid}_${RANDOM}${RANDOM}"
		if ! test -e "${___local_target_tmp_file}" ; then
			break
		fi
	done
	if ! ___write_file_before_hook s3cmd "${___local_target_file}" "${___local_target_tmp_file}" ; then
		return 1
	fi
	if ! _run_sync s3cmd --config "${___s3cmd_configuration_path}" --no-progress get "${___local_source_url}" "${___local_target_tmp_file}"
	then
		_trace error s3cmd "failed fetching S3 file: \`${___local_target_file}\` <- \`${___local_source_url}\`; aborting!"
		return 1
	else
		if ! ___write_file_after_hook s3cmd "${___local_target_file}" "${___local_target_tmp_file}" ; then
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
	_set_failure_message "failed fetching EC2 user data file \`${___local_target_file}\` <- \`${___local_source_url}\`"
	_trace info ec2 "fetching EC2 user data file: \`${___local_target_file}\` <- \`${___local_source_url}\`..."
	local ___local_target_tmp_file=''
	while true ; do
		___local_target_tmp_file="${1}.tmp_${_harness_pid}_${RANDOM}${RANDOM}"
		if ! test -e "${___local_target_tmp_file}" ; then
			break
		fi
	done
	if ! ___write_file_before_hook ec2 "${___local_target_file}" "${___local_target_tmp_file}" ; then
		return 1
	fi
	if ! touch -- "${___local_target_tmp_file}" ; then
		_trace error ec2 "failed creating temporary file: \`${___local_target_tmp_file}\`; aborting!"
		return 1
	fi
	if ! _run_sync curl -s -S \
			-w 'File %{url_effective} saved as '"'${___local_target_tmp_file//%/%%}'"' (%{size_download} bytes in %{time_total} seconds, %{speed_download} B/s)\n' \
			-o "${___local_target_tmp_file}" -- "${___local_source_url}"
	then
		_trace error ec2 "failed fetching EC2 user data file: \`${___local_target_file}\` <- \`${___local_source_url}\`; aborting!"
		return 1
	else
		if ! ___write_file_after_hook ec2 "${___local_target_file}" "${___local_target_tmp_file}" ; then
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
	_set_failure_message "failed fetching file \`${___local_target_file}\` <- \`${___local_source_url}\`"
	_trace info curl "fetching file: \`${___local_target_file}\` <- \`${___local_source_url}\`..."
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
		_trace error curl "failed creating temporary file: \`${___local_target_tmp_file}\`; aborting!"
		return 1
	fi
	if ! _run_sync curl -s -S \
			-w 'File %{url_effective} saved as '"'${___local_target_tmp_file//%/%%}'"' (%{size_download} bytes in %{time_total} seconds, %{speed_download} B/s)\n' \
			-o "${___local_target_tmp_file}" -- "${___local_source_url}"
	then
		_trace error curl "failed fetching file: \`${___local_target_file}\` <- \`${___local_source_url}\`; aborting!"
		return 1
	else
		if ! ___write_file_after_hook curl "${___local_target_file}" "${___local_target_tmp_file}" ; then
			return 1
		fi
	fi
	_unset_failure_message
	return 0
}


_create_folder () {
	test "${#}" -eq 1
	local ___local_target_folder="${1}"
	_set_failure_message "failed creating folder \`${___local_target_folder}\`"
	_trace info library "creating folder: \`${___local_target_folder}\`..."
	_trace debug library "checking target folder path: \`${___local_target_folder}\`..."
	if test -d "${___local_target_folder}" ; then
		_trace warn library "target folder path already exists: \`${___local_target_folder}\`; ignoring!"
		return 0
	elif test -f "${___local_target_folder}" ; then
		_trace error library "target folder path already exists but is a file: \`${___local_target_folder}\`; aborting!"
		return 1
	elif test -e "${___local_target_folder}" ; then
		_trace error library "target folder path already exists but has an unknown type: \`${___local_target_folder}\`; aborting!"
		return 1
	fi
	if ! mkdir -p -- "${___local_target_folder}" ; then
		_trace error library "failed creating folder: \`${___local_target_folder}\`; aborting!"
		return 1
	fi
	_unset_failure_message
	return 0
}


_create_file_inline () {
	test "${#}" -eq 2
	local ___local_target_file="${1}"
	local ___local_target_data="${2}"
	_set_failure_message "failed creating inline file \`${___local_target_file}\`"
	_trace info library "creating inline file: \`${___local_target_file}\`..."
	local ___local_target_tmp_file=''
	while true ; do
		___local_target_tmp_file="${1}.tmp_${_harness_pid}_${RANDOM}${RANDOM}"
		if ! test -e "${___local_target_tmp_file}" ; then
			break
		fi
	done
	if ! ___write_file_before_hook library "${___local_target_file}" "${___local_target_tmp_file}" ; then
		return 1
	fi
	if ! echo -E -n "${___local_target_data}" >"${___local_target_tmp_file}" ; then
		_trace error library "failed creating inline file: \`${___local_target_file}\`; aborting!"
		return 1
	else
		if ! ___write_file_after_hook library "${___local_target_file}" "${___local_target_tmp_file}" ; then
			return 1
		fi
	fi
	_unset_failure_message
	return 0
}


_extract_archive () {
	test "${#}" -eq 3
	local ___local_target_folder="${1}"
	local ___local_archive_file="${2}"
	local ___local_archive_type="${3}"
	_set_failure_message "failed extracting archive \`${___local_target_folder}\` <- \`${___local_archive_file}\`"
	_trace info extract "extracting archive: \`${___local_target_folder}\` <- \`${___local_archive_file}\`..."
	if ! [[ "${___local_archive_type}" =~ ^tar|tar\.gz|tar\.bz2|zip$ ]] ; then
		_trace error extract "invalid archive type: \`${___local_archive_type}\`; aborting!"
		return 1
	fi
	if ! ___check_source_file extract "${___local_archive_file}" ; then
		return 1
	fi
	if ! ___check_target_folder extract "${___local_target_folder}" ; then
		return 1
	fi
	if test "$( ls -AU1 -- "${___local_target_folder}" | wc -l )" -gt 0 ; then
		_trace warn extract "target folder already exists but is not empty: \`${___local_target_folder}\`; overwriting existing files!"
	fi
	local ___local_command=()
	case "${___local_archive_type}" in
		( tar )
			___local_command=( tar -xf "${___local_archive_file}" --no-same-owner --no-same-permissions -C "${___local_target_folder}" )
		;;
		( tar.gz )
			___local_command=( tar -xzf "${___local_archive_file}" --no-same-owner --no-same-permissions -C "${___local_target_folder}" )
		;;
		( tar.bz2 )
			___local_command=( tar -xjf "${___local_archive_file}" --no-same-owner --no-same-permissions -C "${___local_target_folder}" )
		;;
		( zip )
			___local_command=( unzip -q -o "${___local_archive_file}" -d "${___local_target_folder}" )
		;;
		( * )
			_abort library "unexpected code branch; aborting!"
		;;
	esac
	if ! _run_sync "${___local_command[@]}" ; then
		_trace error extract "failed extracting archive: \`${___local_target_folder}\` <- \`${___local_archive_file}\`; aborting!"
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
	_set_failure_message "failed extracting archive \`${___local_target_file}\` <- \`${___local_archive_file}\`"
	_trace info extract "extracting archive: \`${___local_target_file}\` <- \`${___local_archive_file}\`..."
	if ! [[ "${___local_archive_type}" =~ ^gz|bz2$ ]] ; then
		_trace error extract "invalid archive type: \`${___local_archive_type}\`; aborting!"
		return 1
	fi
	if ! ___check_source_file extract "${___local_archive_file}" ; then
		return 1
	fi
	local ___local_target_tmp_file=''
	while true ; do
		___local_target_tmp_file="${1}.tmp_${_harness_pid}_${RANDOM}${RANDOM}"
		if ! test -e "${___local_target_tmp_file}" ; then
			break
		fi
	done
	if ! ___write_file_before_hook extract "${___local_target_file}" "${___local_target_tmp_file}" ; then
		return 1
	fi
	if ! touch -- "${___local_target_tmp_file}" ; then
		_trace error extract "failed creating temporary file: \`${___local_target_tmp_file}\`; aborting!"
		return 1
	fi
	local ___local_command=()
	case "${___local_archive_type}" in
		( gz )
			___local_command=( gunzip )
		;;
		( bz2 )
			___local_command=( bunzip2 )
		;;
		( * )
			_abort library "unexpected code branch; aborting!"
		;;
	esac
	if ! _run_sync_io "${___local_archive_file}" "${___local_target_tmp_file}" "${___local_command[@]}"
	then
		_trace error extract "failed extracting archive: \`${___local_target_file}\` <- \`${___local_archive_file}\`; aborting!"
		return 1
	else
		if ! ___write_file_after_hook extract "${___local_target_file}" "${___local_target_tmp_file}" ; then
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

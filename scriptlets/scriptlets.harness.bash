#!/bin/bash

set -e -u -E -T -C -P +m +b -f +B +H -o pipefail -o posix || exit 1


case "${BASH_VERSION:-<unknown>}" in
	( '4' | '4.'* )
	;;
	( * )
		echo "[!!] [harness ] unsupported Bash version: \`${BASH_VERSION:-<unknown>}\`; aborting!" >&2 || true
		if test "${LOGGER:-true}" == true ; then
			logger "[${0}:${$}] [!!] [harness ] unsupported Bash version: ${BASH_VERSION:-<unknown>}; aborting!" || true
		fi || true
		exit 1
	;;
esac


_harness_pid="${$}"
_harness_name="$( basename -- "${0}" )"
_harness_fingerprint=b829e0d2a9fa7b9e5edbe03821032e42
_harness_shell_path="$( readlink -e -- "${BASH}" )"
_harness_shell_version="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
_harness_debug_enabled="${DEBUG:-false}"
_harness_logger_enabled="${LOGGER:-false}"
_harness_stdin=''
_harness_stdout=''
_harness_stderr=''
___harness_logger_coproc_pipe=''
___harness_logger_coproc_pid=''
___harness_stderr_coproc_pipe=''
___harness_stderr_coproc_pid=''
___harness_stdout_coproc_pipe=''
___harness_stdout_coproc_pid=''


exec {_harness_stdin}<&0 {_harness_stdout}>&1 {_harness_stderr}>&2
exec {___harness_stdout_coproc_pipe}>&1 {___harness_stderr_coproc_pipe}>&2
exec </dev/null


___escaped_quote_tokens=\\\'


___harness_before_exit_script_1='{
	set -e -u -E -T -C -P +m +b -f +B +H -o pipefail -o posix || exit 1
	{
		trap - EXIT ERR DEBUG || true
		trap true SIGHUP SIGINT SIGQUIT SIGUSR1 SIGUSR2 SIGTERM SIGCONT SIGSTOP || true
	} || true
	{
		if test "${_harness_pid}" == "${BASHPID}" ; then
			exec </dev/null >/dev/null 2>/dev/null || true
			test -z "${_harness_stdin:-}" || { exec {_harness_stdin}<&- || true ; _harness_stdin='' ; } || true
			test -z "${_harness_stdout:-}" || { exec {_harness_stdout}>&- || true ; _harness_stdout='' ; } || true
			test -z "${_harness_stderr:-}" || { exec 2>&"${_harness_stderr}" || true ; exec {_harness_stderr}>&- || true ; _harness_stderr='' ; } || true
			test -z "${___harness_stderr_coproc_pipe:-}" || { exec {___harness_stderr_coproc_pipe}>&- || true ; ___harness_stderr_coproc_pipe='' ; } || true
			test -z "${___harness_stdout_coproc_pipe:-}" || { exec {___harness_stdout_coproc_pipe}>&- || true ; ___harness_stdout_coproc_pipe='' ; } || true
			test -z "${___harness_logger_coproc_pipe:-}" || { exec {___harness_logger_coproc_pipe}>&- || true ; ___harness_logger_coproc_pipe='' ; } || true
			test -z "${___harness_stderr_coproc_pid:-}" || { wait -- "${___harness_stderr_coproc_pid}" || true ; ___harness_stderr_coproc_pid='' ; } || true
			test -z "${___harness_stdout_coproc_pid:-}" || { wait -- "${___harness_stdout_coproc_pid}" || true ; ___harness_stdout_coproc_pid='' ; } || true
			test -z "${___harness_logger_coproc_pid:-}" || { wait -- "${___harness_logger_coproc_pid}" || true ; ___harness_logger_coproc_pid='' ; } || true
			wait || true
		else
			wait || true
		fi || true
	} || true
}'

___harness_before_exit_script_2='{
	set -e -u -E -T -C -P +m +b -f +B +H -o pipefail -o posix || exit 1
	{
		if test "${_harness_pid}" == "${BASHPID}" -a -n "${___harness_tmp_queue:-}" -a -f "${___harness_tmp_queue:-}" ; then
			{
				printf -v ___local_message "[ii] [%-8s] cleaning temporary files and folders..." harness || true
				echo "${___local_message}" >&"${_harness_stderr:-2}" || true
				if test "${_harness_logger_enabled}" == true -a -n "${___harness_logger_coproc_pipe}" ; then
					echo "[${_harness_name}:${_harness_pid}] ${___local_message}" >&"${___harness_logger_coproc_pipe}" || true
				fi || true
			} || true
			{
				while read ___local_path ; do
					rm -Rf -- "${___local_path}" || true
				done <"${___harness_tmp_queue}" || true
				rm -f -- "${___harness_tmp_queue}" || true
			} || true
		fi || true
	} || true
}'


___harness_err_trap_script='{
	eval "${___harness_before_exit_script_1}" || true
	set -e -u -E -T -C -P +m +b -f +B +H -o pipefail -o posix || exit 1
	{
		if test -n "${___harness_failure_message:-}" ; then
			printf -v ___local_message "[!!] [%-8s] unexpected failure: %s; aborting!" harness "${___harness_failure_message:-<unknown>}" || true
		else
			printf -v ___local_message "[!!] [%-8s] unexpected failed command: \`%s\` (in function \`%s\`); aborting!" harness "${BASH_COMMAND:-<unknown>}" "${FUNCNAME[0]:-<unknown>}" || true
		fi || true
		echo "${___local_message}" >&"${_harness_stderr:-2}" || true
		if test "${_harness_logger_enabled}" == true -a -n "${___harness_logger_coproc_pipe}" ; then
			echo "[${_harness_name}:${_harness_pid}] ${___local_message}" >&"${___harness_logger_coproc_pipe}" || true
		fi || true
	} || true
	eval "${___harness_before_exit_script_2}" || true
	exit 1
}'


___harness_exit_trap_script='{
	eval "${___harness_before_exit_script_1}" || true
	set -e -u -E -T -C -P +m +b -f +B +H -o pipefail -o posix || exit 1
	{
		printf -v ___local_message "[!!] [%-8s] unexpected exit command: \`%s\` (in function \`%s\`); aborting!" harness "${BASH_COMMAND:-<unknown>}" "${FUNCNAME[0]:-<unknown>}" || true
		echo "${___local_message}" >&"${_harness_stderr:-2}" || true
		if test "${_harness_logger_enabled}" == true -a -n "${___harness_logger_coproc_pipe}" ; then
			echo "[${_harness_name}:${_harness_pid}] ${___local_message}" >&"${___harness_logger_coproc_pipe}" || true
		fi || true
	} || true
	eval "${___harness_before_exit_script_2}" || true
	exit 1
}'


___harness_signal_trap_script='{
	eval "${___harness_before_exit_script_1}" || true
	set -e -u -E -T -C -P +m +b -f +B +H -o pipefail -o posix || exit 1
	{
		printf -v ___local_message "[!!] [%-8s] unexpected signal: \`??\`; aborting!" harness || true
		echo "${___local_message}" >&"${_harness_stderr:-2}" || true
		if test "${_harness_logger_enabled}" == true -a -n "${___harness_logger_coproc_pipe}" ; then
			echo "[${_harness_name}:${_harness_pid}] ${___local_message}" >&"${___harness_logger_coproc_pipe}" || true
		fi || true
	} || true
	eval "${___harness_before_exit_script_2}" || true
	exit 1
}'


___harness_run_before_hook_script='{
	set -e -u -E -T -C -P +m +b -f +B +H -o pipefail -o posix || exit 1
	{
		exec </dev/null >&"${___harness_stdout_coproc_pipe}" 2>&"${___harness_stderr_coproc_pipe}"
		exec {_harness_stdin}<&- {_harness_stdout}>&- {_harness_stderr}>&-
		exec {___harness_stderr_coproc_pipe}>&- {___harness_stdout_coproc_pipe}>&-
		if test -n "${___harness_logger_coproc_pipe}" ; then
			exec {___harness_logger_coproc_pipe}>&-
		fi
	}
}'


___harness_run_fg_before_hook_script='{
	set -e -u -E -T -C -P +m +b -f +B +H -o pipefail -o posix || exit 1
	{
		exec <&"${_harness_stdin}" >&"${_harness_stdout}" 2>&"${_harness_stderr}"
		exec {_harness_stdin}<&- {_harness_stdout}>&- {_harness_stderr}>&-
		exec {___harness_stderr_coproc_pipe}>&- {___harness_stdout_coproc_pipe}>&-
		if test -n "${___harness_logger_coproc_pipe}" ; then
			exec {___harness_logger_coproc_pipe}>&-
		fi
	}
}'


trap "${___harness_err_trap_script}" ERR
trap "${___harness_exit_trap_script}" EXIT
trap "${___harness_signal_trap_script}" SIGHUP SIGINT SIGQUIT SIGUSR1 SIGUSR2 SIGTERM SIGCONT SIGSTOP


_set_failure_message () {
	test "${#}" -eq 1
	___harness_failure_message="${1}"
	___harness_failure_message_stack+=( "${___harness_failure_message}" )
	return 0
}

_unset_failure_message () {
	test "${#}" -eq 0
	unset ___harness_failure_message_stack["${#___harness_failure_message_stack[@]}"-1]
	if test "${#___harness_failure_message_stack[@]}" -ge 1 ; then
		___harness_failure_message="${___harness_failure_message_stack[${#___harness_failure_message_stack[@]}-1]}"
	else
		___harness_failure_message=''
	fi
	return 0
}


___harness_configuration () {
	test "${#}" -eq 0
	
	_set_failure_message 'unknown harness configuration error'
	
	umask 0077
	
	___harness_tmp_path="${TMPDIR:-/tmp}"
	___harness_tmp_prefix="$( basename -- "${0}" )"
	
	if ! test -e "${___harness_tmp_path}" ; then
		_trace warn harness "temporary folder does not exist: \`${___harness_tmp_path}\`; ignoring!"
	elif ! test -d "${___harness_tmp_path}" ; then
		_trace error harness "temporary folder already exists and is a file: \`${___harness_tmp_path}\`; ignoring!"
	fi
	
	___harness_core_script_path="${0}"
	___harness_main_script_path=''
	___harness_library_script_path=''
	
	local ___local_cwd=''
	local ___local_core_path=''
	local ___local_core_dirname=''
	local ___local_core_basename=''
	local ___local_core_prefix=''
	local ___local_core_suffix=''
	local ___local_main_path=''
	local ___local_library_path=''
	local ___local_tmp_prefix=''
	
	___local_core_path="${0}"
	if test -h "${___local_core_path}" ; then
		_trace debug harness "core script is a symlink: \`${___local_core_path}\`"
	fi
	
	___local_cwd="$( readlink -e -- "$( pwd )" )"
	test -d "${___local_cwd}"
	
	while true ; do
		
		___local_core_dirname="$( dirname -- "${___local_core_path}" )"
		___local_core_basename="$( basename -- "${___local_core_path}" )"
		
		test -d "${___local_core_dirname}"
		cd -- "${___local_core_dirname}"
		test -f "./${___local_core_basename}"
		
		case "${___local_core_basename}" in
			( *'.bash' )
				___local_core_prefix="${___local_core_basename%%.bash}"
				___local_core_suffix='.bash'
			;;
			( *'.sh' )
				___local_core_prefix="${___local_core_basename%%.sh}"
				___local_core_suffix='.sh'
			;;
			( * )
				_trace debug harness "core script has an unknown name pattern: \`${___local_core_path}\`; ignoring!"
				___local_core_prefix="${___local_core_basename}"
				___local_core_suffix=''
			;;
		esac
		
		___local_main_path="./${___local_core_prefix}.main.bash"
		___local_library_path="./${___local_core_prefix}.library.bash"
		___local_tmp_prefix="${___local_core_prefix}"
		
		if test -z "${___harness_main_script_path}" -a -f "${___local_main_path}" ; then
			___harness_main_script_path="$( readlink -e -- "${___local_main_path}" )"
			___harness_tmp_prefix="${___local_tmp_prefix}"
			_trace debug harness "main script found: \`${___harness_main_script_path}\`"
		fi
		
		if test -z "${___harness_library_script_path}" -a -f "${___local_library_path}" ; then
			___harness_library_script_path="$( readlink -e -- "${___local_library_path}" )"
			_trace debug harness "library script found: \`${___harness_library_script_path}\`"
		fi
		
		if test -n "${___harness_main_script_path}" -a -n "${___harness_library_script_path}" ; then
			break
		fi
		
		if test -h "./${___local_core_basename}" ; then
			___local_core_path="$( readlink -- "./${___local_core_basename}" )"
			_trace debug harness "following core script symlink: \`${___local_core_dirname}/${___local_core_basename}\` -> \`${___local_core_path}\`..."
		elif test -n "${___harness_main_script_path}" ; then
			_trace debug harness "main script found but no library script; ignoring! (check core script symlink chain!)"
			break
		else
			_abort harness "main script not found for: \`${___harness_core_script_path}\`; aborting!"
		fi
		
	done
	
	cd -- "${___local_cwd}"
	
	if test -n "${___harness_main_script_path}" ; then
		test -f "${___harness_main_script_path}"
	fi
	
	if test -n "${___harness_library_script_path}" ; then
		test -f "${___harness_library_script_path}"
	fi
	
	___harness_tmp_queue="${___harness_tmp_path}/${___harness_tmp_prefix}.tmp_queue_${_harness_pid}_${RANDOM}${RANDOM}"
	
	_unset_failure_message
	return 0
}


___harness_coprocs () {
	test "${#}" -eq 0
	
	_set_failure_message 'unknown harness coprocs error'
	
	local ___local_logger_pipe=''
	local ___local_stdout_pipe=''
	local ___local_stderr_pipe=''
	local ___local_harness_name="${_harness_name}"
	local ___local_harness_pid="${_harness_pid}"
	
	___local_harness_name="${___local_harness_name//\\/\\\\}"
	___local_harness_name="${___local_harness_name//!/\\!}"
	___local_harness_name="${___local_harness_name//&/\\&}"
	___local_harness_pid="${___local_harness_pid//\\/\\\\}"
	___local_harness_pid="${___local_harness_pid//!/\\!}"
	___local_harness_pid="${___local_harness_pid//&/\\&}"
	
	if test "${_harness_logger_enabled}" == true ; then
		___local_logger_pipe="${___harness_tmp_path}/${___harness_tmp_prefix}.tmp_logger_${_harness_pid}_${RANDOM}${RANDOM}"
		mkfifo -- "${___local_logger_pipe}"
		(
			exec </dev/null >/dev/null 2>&"${_harness_stderr}"
			exec {_harness_stdin}<&- {_harness_stdout}>&- {_harness_stderr}>&-
			exec <"${___local_logger_pipe}"
			exec logger
			exit 1
		) &
		___harness_logger_coproc_pid="${!}"
		disown "${___harness_logger_coproc_pid}"
	fi
	
	if test -n "${___local_logger_pipe}" ; then
		exec {___harness_logger_coproc_pipe}>"${___local_logger_pipe}"
		rm -f -- "${___local_logger_pipe}"
	fi
	
	if true ; then
		___local_stderr_pipe="${___harness_tmp_path}/${___harness_tmp_prefix}.tmp_stderr_${_harness_pid}_${RANDOM}${RANDOM}"
		mkfifo -- "${___local_stderr_pipe}"
		(
			exec </dev/null >/dev/null 2>&"${_harness_stderr}"
			exec {_harness_stdin}<&- {_harness_stdout}>&- {_harness_stderr}>&-
			exec <"${___local_stderr_pipe}"
			if test -n "${___harness_logger_coproc_pipe}" ; then
				exec sed -u -r \
						-e 's!^.*$![ #]              &!' -e 'w /dev/stderr' \
						-e 's!^.*$!'"[${___local_harness_name}:${___local_harness_pid}]"' &!' \
					>&"${___harness_logger_coproc_pipe}"
			else
				exec sed -u -r -e 's!^.*$![ #]              &!' >&2
			fi
			exit 1
		) &
		___harness_stderr_coproc_pid="${!}"
		disown "${___harness_stderr_coproc_pid}"
	fi
	
	if true ; then
		___local_stdout_pipe="${___harness_tmp_path}/${___harness_tmp_prefix}.tmp_stdout_${_harness_pid}_${RANDOM}${RANDOM}"
		mkfifo -- "${___local_stdout_pipe}"
		(
			exec </dev/null >/dev/null 2>&"${_harness_stderr}"
			exec {_harness_stdin}<&- {_harness_stdout}>&- {_harness_stderr}>&-
			exec <"${___local_stdout_pipe}"
			if test -n "${___harness_logger_coproc_pipe}" ; then
				exec sed -u -r \
						-e 's!^.*$![ >]              &!' -e 'w /dev/stderr' \
						-e 's!^.*$!'"[${___local_harness_name}:${___local_harness_pid}]"' &!' \
					>&"${___harness_logger_coproc_pipe}"
			else
				exec sed -u -r -e 's!^.*$![ >]              &!' >&2
			fi
			exit 1
		) &
		___harness_stdout_coproc_pid="${!}"
		disown "${___harness_stdout_coproc_pid}"
	fi
	
	if test -n "${___local_stderr_pipe}" ; then
		exec {___harness_stderr_coproc_pipe}>&-
		exec {___harness_stderr_coproc_pipe}>"${___local_stderr_pipe}"
		exec 2>&"${___harness_stderr_coproc_pipe}"
		rm -f -- "${___local_stderr_pipe}"
	fi
	
	if test -n "${___local_stdout_pipe}" ; then
		exec {___harness_stdout_coproc_pipe}>&-
		exec {___harness_stdout_coproc_pipe}>"${___local_stdout_pipe}"
		exec >&"${___harness_stdout_coproc_pipe}"
		rm -f -- "${___local_stdout_pipe}"
	fi
	
	_unset_failure_message
	return 0
}


___harness_main () {
	
	_set_failure_message 'unknown harness error'
	
	if test -n "${___harness_library_script_path}" ; then
		_trace debug harness "sourcing library script: \`${___harness_library_script_path}\`..."
		_source "${___harness_library_script_path}"
	else
		_trace debug harness "no library script found; ignoring!"
	fi
	
	_trace debug harness "sourcing main script: \`${___harness_main_script_path}\`..."
	_source "${___harness_main_script_path}" "${@}"
	
	_abort harness "main script should not return; aborting!"
	exit 1
	return 1
}


_exit () {
	test "${#}" -eq 1
	eval "${___harness_before_exit_script_1}"
	_trace debug harness "exiting with code ${1}"
	eval "${___harness_before_exit_script_2}"
	exit "${1}"
	exit 1
}

_abort () {
	test "${#}" -eq 2
	_trace fatal "${1}" "${2}"
	eval "${___harness_before_exit_script_1}"
	_trace debug harness "exiting with code 1"
	eval "${___harness_before_exit_script_2}"
	exit 1
}


_trace () {
	test "${#}" -eq 3
	local ___local_message=''
	case "${1}" in
		( info )
			printf -v ___local_message "[ii] [%-8s] %s" "${2}" "${3}"
		;;
		( warn )
			printf -v ___local_message "[ww] [%-8s] %s" "${2}" "${3}"
		;;
		( error )
			printf -v ___local_message "[ee] [%-8s] %s" "${2}" "${3}"
		;;
		( fatal )
			printf -v ___local_message "[!!] [%-8s] %s" "${2}" "${3}"
		;;
		( exec )
			printf -v ___local_message "[xx] [%-8s] %s" "${2}" "${3}"
		;;
		( debug )
			if test "${_harness_debug_enabled}" == true ; then
				printf -v ___local_message "[  ] [%-8s] %s" "${2}" "${3}"
			fi
		;;
		( * )
			printf -v ___local_message "[??] [%-8s] %s" "${2}" "${3}"
		;;
	esac
	if test -n "${___local_message}" ; then
		echo "${___local_message}" >&"${_harness_stderr:-2}"
		if test "${_harness_logger_enabled}" == true -a -n "${___harness_logger_coproc_pipe}" ; then
			echo "[${_harness_name}:${_harness_pid}] ${___local_message}" >&"${___harness_logger_coproc_pipe}"
		fi
	fi
	return 0
}


_source () {
	test "${#}" -ge 1
	_set_failure_message "failed sourcing file \`${1}\`"
	_trace debug harness "sourcing file: \`${1}\`..."
	if ! test -f "${1}" ; then
		_trace error harness "sourced file does not exist: \`${1}\`; aborting!"
		return 1
	fi
	local ___local_errors="$( exec "${_harness_shell_path}" -n -- "${1}" 2>&1 )" ___local_outcome="${?}"
	if test "${___local_outcome}" -ne 0 ; then
		_trace error harness "sourced file can not be loaded: \`${1}\`; aborting!"
		local ___local_line=''
		while read ___local_line ; do
			_trace error harness "  ${___local_line}"
		done <<<"${___local_errors}"
		return 1
	fi
	source "${1}" -- "${@:2}"
	_unset_failure_message
	return 0
}


_run_sync () {
	test "${#}" -ge 1
	_set_failure_message "failed running synchronous command \`${*}\`"
	_trace debug harness "running synchronous command: \`${*}\`..."
	if ( eval "${___harness_run_before_hook_script}" && exec "${@}" || exit 1 ; ) ; then
		_unset_failure_message
		return 0
	else
		return "${?}"
	fi
}


_run_sync_io () {
	test "${#}" -ge 3
	local ___local_stdin="${1}"
	local ___local_stdout="${2}"
	shift 2
	_set_failure_message "failed running synchronous command \`${*}\`"
	_trace debug harness "running synchronous command: \`${*}\`..."
	if ( eval "${___harness_run_before_hook_script}" && exec "${@}" <"${___local_stdin}" >|"${___local_stdout}" || exit 1 ; ) ; then
		_unset_failure_message
		return 0
	else
		return "${?}"
	fi
}


_run_async () {
	test "${#}" -ge 1
	_set_failure_message "failed running asynchronous command \`${*}\`"
	_trace debug harness "running asynchronous command: \`${*}\`..."
	if ( eval "${___harness_run_before_hook_script}" && exec "${@}" || exit 1 ; ) & then
		_unset_failure_message
		return 0
	else
		return 1
	fi
}


_run_fg () {
	test "${#}" -ge 1
	_set_failure_message "failed running foreground command \`${*}\`"
	_trace debug harness "running foreground command: \`${*}\`..."
	if ( eval "${___harness_run_fg_before_hook_script}" && exec "${@}" || exit 1 ; ) ; then
		_unset_failure_message
		return 0
	else
		return "${?}"
	fi
}


_tmp_create_file () {
	test "${#}" -ge 1 -a "${#}" -le 4
	_set_failure_message "failed creating temporary file"
	[[ "${1}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]
	[[ "${2:-}" =~ ^([A-Za-z0-9_-]+)?$ ]]
	[[ "${3:-}" =~ ^(\.[A-Za-z0-9_-]+)?$ ]]
	if test -n "${4:-}" ; then test -d "${4}" ; local ___local_prefix="${4}/" ; else local ___local_prefix="${___harness_tmp_path}/${___harness_tmp_prefix}--" ; fi
	local ___local_path='/' ; while test -e "${___local_path}" ; do ___local_path="${___local_prefix}${2:-${1}}${3:-}.${_harness_pid}_${RANDOM}${RANDOM}" ; done
	_trace debug harness "creating temporary file: \`${___local_path}\`..."
	_tmp_enqueue "${___local_path}"
	echo >"${___local_path}"
	eval "${1}='${___local_path//\'/'${___escaped_quote_tokens}'}'"
	_unset_failure_message
	return 0
}


_tmp_create_folder () {
	test "${#}" -ge 1 -a "${#}" -le 4
	_set_failure_message "failed creating temporary folder"
	[[ "${1}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]
	[[ "${2:-}" =~ ^([A-Za-z0-9_-]+)?$ ]]
	[[ "${3:-}" =~ ^(\.[A-Za-z0-9_-]+)?$ ]]
	if test -n "${4:-}" ; then test -d "${4}" ; local ___local_prefix="${4}/" ; else local ___local_prefix="${___harness_tmp_path}/${___harness_tmp_prefix}--" ; fi
	local ___local_path='/' ; while test -e "${___local_path}" ; do ___local_path="${___local_prefix}${2:-${1}}${3:-}.${_harness_pid}_${RANDOM}${RANDOM}" ; done
	_trace debug harness "creating temporary folder: \`${___local_path}\`..."
	_tmp_enqueue "${___local_path}"
	mkdir -- "${___local_path}"
	eval "${1}='${___local_path//\'/'${___escaped_quote_tokens}'}'"
	_unset_failure_message
	return 0
}


_tmp_enqueue () {
	test "${#}" -eq 1
	_set_failure_message "failed enqueueing temporary path"
	_trace debug harness "enqueueing temporary file: \`${1}\`..."
	echo "${1}" >>"${___harness_tmp_queue}"
	_unset_failure_message
	return 0
}


___harness_configuration
___harness_coprocs
___harness_main "${@}"
exit 1

#!/bin/bash

set -e -u -E -T -C -P +m +b -f +B -H -o pipefail +o posix || exit 1

trap '{ echo "[ee] unchecked failed command: \`${BASH_COMMAND:-<unknown>}\`; aborting!" >&2 ; exit 1 ; }' ERR

if test "${#}" -lt 2
then
	echo "[ee] wrong arguments!" >&2
	echo "[ii] usage: ${0} <expansion-folder> <compression> <delegate-file> [<dependency-files>*]" >&2
	echo "[ii]     <expansion-folder>: when the resulting script is run" >&2
	echo "[ii]         it will create a folder with this pattern" >&2
	echo "[ii]         but appending the PID of the script" >&2
	echo "[ii]     <compression>: none | gzip | bzip2 | lzma" >&2
	echo "[ii]     <delegate-file>: when the resulting script is run" >&2
	echo "[ii]         and after expanding the contained files" >&2
	echo "[ii]         it will run this file (which could be a binary" >&2
	echo "[ii]         or a script) with the current directory changed" >&2
	echo "[ii]         to the expansion folder and with any given arguments" >&2
	echo "[ii]     <dependency-files>: any other files that might be needed" >&2
	exit 1
fi

_expand_path="${1}"
shift
_compress="${1}"
shift

_main_source_path="${1}"

[[ "${_expand_path}" =~ ^\.?(/[A-Za-z0-9]([-_]?[A-Za-z0-9]+)*)+$ ]]
[[ "${_compress}" =~ ^gzip|bzip2|lzma|none$ ]]

test -f "${_main_source_path}"
test -x "${_main_source_path}"

_quote_token=\\\'
_parent_target_path="$( dirname -- "${_expand_path}" )"
_parent_target_path_token="'${_parent_target_path//\'/'${_quote_token}'}'"

_expand_target_path="${_expand_path}"
_expand_target_path_token="'${_expand_target_path//\'/'${_quote_token}'}'\"--\${_self}\""

_main_name="$( basename -- "${_main_source_path}" )"
_main_name_token="'${_main_name//\'/'${_quote_token}'}'"

for _dependency_source_path in "${@}"
do
	test -f "${_dependency_source_path}"
done

echo "#!/bin/sh"

echo "umask 0077 || exit 1"
echo "_self=\"\${\$}\""

echo "test -e ${_parent_target_path_token} \\"
echo "|| { echo '[ee] expand parent folder \`'${_parent_target_path_token}'\` not found; aborting!' >&2 ; exit 1 ; }"

echo "test -d ${_parent_target_path_token} \\"
echo "|| { echo '[ee] expand parent folder \`'${_parent_target_path_token}'\` is a file; aborting!' >&2 ; exit 1 ; }"

echo "test ! -e ${_expand_target_path_token} \\"
echo "|| rm -rf ${_expand_target_path_token} \\"
echo "|| { echo '[ee] unable to remove bundle folder \`'${_expand_target_path_token}'\`; aborting!' >&2 ; exit 1 ; }"

echo "mkdir ${_expand_target_path_token} \\"
echo "|| { echo '[ee] unable to create bundle folder \`'${_expand_target_path_token}'\`; aborting!' >&2 ; exit 1 ; }"

for _dependency_source_path in "${@}"
do
	test -f "${_dependency_source_path}"
	_dependency_name="$( basename -- "${_dependency_source_path}" )"
	_dependency_name_token="'${_dependency_name//\'/'${_quote_token}'}'"
	_dependency_md5sum="$( md5sum -b -- "${_dependency_source_path}" | grep -o -E -e '^[0-9a-f]+' )"
	_dependency_target_path_token="${_expand_target_path_token}'/'${_dependency_name_token}"
	case "${_compress}" in
		( none )
			_compress_command=( cat )
			_compress_ext=""
			_uncompress_tokens=""
		;;
		( gzip )
			_compress_command=( gzip -9 )
			_compress_ext="'.gz'"
			_uncompress_tokens="gunzip"
		;;
		( bzip2 )
			_compress_command=( bzip2 -9 )
			_compress_ext="'.bz2'"
			_uncompress_tokens="bunzip2"
		;;
		( lzma )
			_compress_command=( lzma -9 )
			_compress_ext="'.lzma'"
			_uncompress_tokens="unlzma"
		( * )
			exit 1
		;;
	esac
	"${_compress_command[@]}" <"${_dependency_source_path}" \
	| while true
	do
		__chunk="$( head -c 131072 | base64 | sed -r -e 's!'\''!\\'\''!g' )"
		test -n "${__chunk}" || break
		echo "echo '"
		echo "${__chunk}"
		echo "' \\"
		echo "| base64 -i -d \\"
		echo ">>${_dependency_target_path_token}${_compress_ext} \\"
		echo "|| { echo '[ee] unable to create dependency file \`'${_dependency_target_path_token}'${_compress_ext}\`; aborting!' >&2 ; exit 1 ; }"
	done
	if test -n "${_uncompress_tokens}${_compress_ext}"
	then
		echo "${_uncompress_tokens} ${_dependency_target_path_token}${_compress_ext} \\"
		echo "|| { echo '[ee] unable to uncompress dependency file \`'${_dependency_target_path_token}'${_compress_ext}\`; aborting!' >&2 ; exit 1 ; }"
	fi
	echo "_md5sum=\"\$( md5sum -b <${_dependency_target_path_token} )\""
	echo "test \"\${_md5sum}\" = '${_dependency_md5sum} *-' -o \"\${_md5sum}\" = '${_dependency_md5sum}  -' \\"
	echo "|| { echo '[ee] wrong md5sum for dependency file \`'${_dependency_target_path_token}'\`; aborting!' >&2 ; exit 1 ; }"
	echo "unset _md5sum"
	if test -x "${_dependency_source_path}"
	then
		echo "chmod +x ${_dependency_target_path_token} \\"
		echo "|| { echo '[ee] unable to chmod dependency file \`'${_dependency_target_path_token}'\`; aborting!' >&2 ; exit 1 ; }"
	fi
done

echo "cd ${_expand_target_path_token} \\"
echo "|| { echo '[ee] unable to chdir folder \`'${_expand_target_path_token}'\`; aborting!' >&2 ; exit 1 ; }"

for _signal in HUP INT QUIT TERM CONT STOP
do
	if test "${_signal}" == INT
	then
		_trap_signal="${_signal}"
		_send_signal=TERM
	else
		_trap_signal="${_signal}"
		_send_signal="${_signal}"
	fi
	echo "trap '{ echo \"[ii] killing the child process \\\`\${!}\\\` with signal \\\`${_send_signal}\\\`... \" >&2 ; kill -s '${_send_signal}' \"\${!}\" || true ; }' ${_trap_signal} || true"
done

echo "outcome=0"
echo "test \"\${#}\" -ne 0 \\"
echo "|| { './'${_main_name_token} & } \\"
echo "|| { outcome=\"\${?}\" ; echo '[ee] failed to execute main file \`./'${_main_name_token}'\`; aborting!' >&2 ; }"
echo "test \"\${#}\" -eq 0 \\"
echo "|| { './'${_main_name_token} \"\${@}\" & } \\"
echo "|| { outcome=\"\${?}\" ; echo '[ee] failed to execute main file \`./'${_main_name_token}'\`; aborting!' >&2 ; }"

echo "test \"\${outcome}\" -ne 0 || while test -e \"/proc/\${!}\" ; do wait \"\${!}\" ; done || outcome=\"\${?}\""

echo "rm -rf ${_expand_target_path_token} \\"
echo "|| { echo '[ee] unable to remove bundle folder \`'${_expand_target_path_token}'\`; aborting!' >&2 ; exit 1 ; }"

echo "exit \"\${outcome}\""

exit 0

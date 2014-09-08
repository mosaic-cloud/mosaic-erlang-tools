#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

cat <<EOS

${_package_name}@requisites : \
		pallur-packages@erlang-${_otp_version} \
		pallur-packages@vbs \
		pallur-packages@ninja \
		pallur-environment

# FIXME: Move these to the requisites of 'mosaic-node'!
${_package_name}@requisites : \
		pallur-packages@jansson

# FIXME: Move these to the requisites of 'mosaic-components-couchdb'!
${_package_name}@requisites : \
		pallur-packages@js-1.8.5 \
		pallur-packages@nspr-4.9

# FIXME: Move these to the requisites of 'mosaic-components-riak-kv'!
${_package_name}@requisites : \
		pallur-packages@js-1.8.0 \
		pallur-packages@nspr-4.8

${_package_name}@prepare : ${_package_name}@requisites
	!exec ${_scripts}/prepare

${_package_name}@package : ${_package_name}@compile
	!exec ${_scripts}/package

${_package_name}@compile : ${_package_name}@prepare
	!exec ${_scripts}/compile

${_package_name}@deploy : ${_package_name}@package
	!exec ${_scripts}/deploy

EOS

exit 0

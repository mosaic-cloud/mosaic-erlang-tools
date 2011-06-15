#!/dev/null

_erl_path=''

_erl_run_argv=(
	+Bd +Ww
	-env ERL_CRASH_DUMP /dev/null
	-env ERL_LIBS "${_deployment_erlang_path}/lib"
	-noshell -noinput
	-config "${_deployment_erlang_path}/lib/{...}/priv/{...}.config"
	-run {...} {...}
)

_ez_bundle_names=(
	{...}
)

_bundles_base_url="{...}"
_bundles_base_path="{...}"

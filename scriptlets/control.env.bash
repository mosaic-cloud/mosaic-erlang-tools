#!/dev/null

_erl_args+=(
	-noshell -noinput
	-sname "{...}"
	-config "${_deployment_erlang_path}/lib/{...}/priv/{...}.config"
	-run "{...}" "{...}"
)

_ez_bundle_names=(
	"{...}"
)

_bundles_base_url="{...}"
_bundles_base_path="{...}"

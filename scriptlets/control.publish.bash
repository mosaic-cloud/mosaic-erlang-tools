#!/bin/bash

set -e -u -o pipefail || exit 1
test "${#}" -eq 0

_deployment_path="/tmp/mosaic-temporary"
_deployment_bundles_path="${_deployment_path}/bundles"
_deployment_erlang_path="${_deployment_path}/erlang"
_deployment_data_path="${_deployment_path}/data"

source ./scripts/control.env.bash

_files=(
	./.repositories/mosaic-erlang-dependencies/scriptlets/control.premain.bash
	./.repositories/mosaic-erlang-dependencies/scriptlets/control.main.bash
	./.repositories/mosaic-erlang-dependencies/scriptlets/scriptlets.harness.bash
	./.repositories/mosaic-erlang-dependencies/scriptlets/scriptlets.library.bash
	./scripts/control.env.bash
)

if test -e ./.tools/bash.elf ; then
	_files+=( ./.tools/bash.elf )
fi

echo "[ii] creating \`control.sh\`..." >&2
bash ./.repositories/mosaic-erlang-dependencies/scriptlets/scriptlets.bundle.bash \
		/tmp/mosaic-erlang-control gzip "${_files[@]}" \
		>./.outputs/control.sh
chmod +x ./.outputs/control.sh

echo "[ii] publishing \`control.sh\`..." >&2
cp -T -- ./.outputs/control.sh "${_bundles_base_path}/control.sh"

for _ez_bundle_name in "${_ez_bundle_names[@]}" ; do
	echo "[ii] publishing \`${_ez_bundle_name}.ez\`..." >&2
	cp -T -- "./.outputs/erlang/applications-ez/${_ez_bundle_name}.ez" "${_bundles_base_path}/${_ez_bundle_name}.ez"
done

exit 0

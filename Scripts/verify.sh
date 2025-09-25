#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

pushd "${REPO_ROOT}" >/dev/null

swift --version

./Scripts/asset-index.swift

swift build -c release
swift test --parallel

popd >/dev/null

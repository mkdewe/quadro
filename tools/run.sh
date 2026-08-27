#!/usr/bin/env bash
# Convenience wrapper around `docker run` for the quadro image.
#
#   tools/run.sh examples/pz74.inp
#   tools/run.sh --alt --outdir out examples/pz74.inp
#
# Paths are given relative to the repository root, which is mounted at /work.
# Everything after the options is passed straight through to the container
# entrypoint — see `tools/run.sh --help` for the full option list.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$REPO/VERSION")"
IMAGE="${QUADRO_IMAGE:-quadro$(echo "$VERSION" | tr '[:upper:]' '[:lower:]'):latest}"

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "run.sh: image '$IMAGE' not found. Build it first:" >&2
    echo "        tools/build.sh" >&2
    exit 70
fi

exec docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$REPO:/work" \
    "$IMAGE" "$@"

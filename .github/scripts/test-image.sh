#!/usr/bin/env bash
# Test image of this repo. Makes sure that the image built from an image
# folder of the repo (e.g. docker/browser/) is in the machine's local
# registry, and gives its name to the test jobs. The tag is the build date and
# a hash of the folder's files, so the image is built again only when the
# Dockerfile or the files it uses change in git. The three newest versions of
# the image are kept.
#
# Run by the job "Test image" of the test workflows, directly on the machine:
#   bash .github/scripts/test-image.sh docker/browser
# The image is localhost:5000/<repo>-<folder>, e.g. robot-demo-browser. Writes
# image=<image:tag> to $GITHUB_OUTPUT and a short table to the Summary page.

set -euo pipefail

DIR="${1:?give the image folder, e.g. docker/browser}"
DIR="${DIR%/}"
REPO="${GITHUB_REPOSITORY:-local/$(basename "$(pwd)")}"
NAME="$(tr 'A-Z_' 'a-z-' <<< "$(basename "${REPO}")-$(basename "${DIR}")")"
REGISTRY="localhost:5000"
KEEP=3
REQUESTS="/var/lib/runner-kit/requests"
OUTPUT="${GITHUB_OUTPUT:-/dev/stdout}"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"
MANIFEST_TYPES=(
    -H 'Accept: application/vnd.oci.image.index.v1+json'
    -H 'Accept: application/vnd.oci.image.manifest.v1+json'
    -H 'Accept: application/vnd.docker.distribution.manifest.list.v2+json'
    -H 'Accept: application/vnd.docker.distribution.manifest.v2+json'
)

die() {
    echo "ERROR: $*" >&2
    printf '## Test image: ❌ %s\n' "$*" >> "${SUMMARY}"
    exit 1
}

# Versions of the image (YYYY.MM.DD-hash), oldest first.
versions() {
    curl -fsS "http://${REGISTRY}/v2/${NAME}/tags/list" 2>/dev/null \
        | jq -r '.tags // [] | .[]' | grep -E '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}-[0-9a-f]{12}$' | sort || true
}

# Manifest digest of a tag. Empty if the tag does not exist.
digest() {
    curl -fsSI "${MANIFEST_TYPES[@]}" "http://${REGISTRY}/v2/${NAME}/manifests/$1" 2>/dev/null \
        | tr -d '\r' | awk -F': ' 'tolower($1) == "docker-content-digest" { print $2 }' || true
}

[[ -f "${DIR}/Dockerfile" ]] || die "${DIR}/Dockerfile does not exist in the repo"
curl -fsS "http://${REGISTRY}/v2/" >/dev/null || die "the machine's local registry does not respond (${REGISTRY})"

# Hash of the folder: the names and contents of its files.
HASH="$(cd "${DIR}" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | cut -c1-12)"

# One job at a time looks for or builds an image of this name. The others wait
# here and then find the image ready.
exec 9> "/tmp/test-image-${NAME}.lock"
flock -w 3600 9 || die "waited an hour for another build of ${NAME}"

TAG="$(versions | grep -E -- "-${HASH}$" | tail -n 1 || true)"
REMOVED=()
if [[ -n "${TAG}" ]]; then
    STATE="found in the registry, not built"
else
    TAG="$(date +%Y.%m.%d)-${HASH}"
    START="$(date +%s)"
    echo "== Building ${REGISTRY}/${NAME}:${TAG} from ${DIR}/ =="
    # Version and build time also inside the image, if the Dockerfile has the
    # ARGs, so a test run can show which image it used.
    OPTIONS=(--pull --label "runner-kit.source=${REPO}/${DIR}"
        --build-arg "IMAGE_VERSION=${TAG}"
        --build-arg "IMAGE_BUILT=$(date '+%Y-%m-%d %H:%M')")
    # Without the provenance attachment the registry gets one plain manifest.
    if docker buildx version >/dev/null 2>&1; then
        OPTIONS+=(--provenance=false)
    fi
    docker build "${OPTIONS[@]}" -t "${REGISTRY}/${NAME}:${TAG}" "${DIR}" \
        || die "building ${NAME} from ${DIR}/ failed, see the step log"
    docker push "${REGISTRY}/${NAME}:${TAG}" || die "pushing ${NAME} to the local registry failed"
    STATE="built now ($(( $(date +%s) - START )) s)"

    echo "== Removing old versions (the ${KEEP} newest remain) =="
    mapfile -t ALL < <(versions)
    for old in "${ALL[@]:0:$(( ${#ALL[@]} > KEEP ? ${#ALL[@]} - KEEP : 0 ))}"; do
        [[ "${old}" != "${TAG}" ]] || continue
        OLD_DIGEST="$(digest "${old}")"
        if [[ -n "${OLD_DIGEST}" ]] && curl -fsS -X DELETE "http://${REGISTRY}/v2/${NAME}/manifests/${OLD_DIGEST}" >/dev/null; then
            echo "Removed ${old}"
            REMOVED+=("${old}")
        else
            echo "Warning: removing version ${old} failed"
        fi
        docker image rm "${REGISTRY}/${NAME}:${old}" >/dev/null 2>&1 || true
    done
    # The registry frees the space of removed versions in its cleanup (as root).
    if (( ${#REMOVED[@]} > 0 )) && [[ -w "${REQUESTS}" ]]; then
        touch "${REQUESTS}/cleanup"
    fi
fi

IMAGE="${REGISTRY}/${NAME}:${TAG}"
echo "Test image: ${IMAGE} (${STATE})"
echo "image=${IMAGE}" >> "${OUTPUT}"
{
    echo "## Test image: ✅ \`${IMAGE}\`"
    echo
    echo "| | |"
    echo "|---|---|"
    echo "| Image folder | \`${DIR}/\` (hash ${HASH}) |"
    echo "| Image | ${STATE} |"
    if (( ${#REMOVED[@]} > 0 )); then
        echo "| Removed old versions | ${REMOVED[*]} |"
    fi
    echo
    echo "_The image is built again only when the files of \`${DIR}/\` change._"
} >> "${SUMMARY}"

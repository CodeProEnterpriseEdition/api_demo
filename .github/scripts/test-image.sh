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
# The folder is the build context, so the Dockerfile copies files of the folder.
#
# Files from elsewhere in the repo, e.g. a uv project's pyproject.toml and
# uv.lock in the repo root, are given after the folder:
#   bash .github/scripts/test-image.sh docker/api pyproject.toml uv.lock
# Then the build context is the repo root, but it holds only the folder and the
# files given, so the Dockerfile copies them with their paths from the root
# (COPY pyproject.toml uv.lock ./). The hash covers the same files, and a file
# the Dockerfile copies but that is not given fails the build.
#
# The image is localhost:5000/<repo>-<folder>, e.g. my-tests-browser for the
# folder docker/browser/ of the repo my-tests. Writes image=<image:tag> to
# $GITHUB_OUTPUT and a short table to the Summary page.

set -euo pipefail

DIR="${1:?give the image folder, e.g. docker/browser}"
DIR="${DIR%/}"
shift
EXTRA=("$@")
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
for f in "${EXTRA[@]}"; do
    [[ "${f}" != /* && "/${f}/" != */../* ]] || die "give the files with their paths from the repo root (got: ${f})"
    [[ -e "${f}" ]] || die "${f} does not exist in the repo"
done
curl -fsS "http://${REGISTRY}/v2/" >/dev/null || die "the machine's local registry does not respond (${REGISTRY})"

# Hash of the files the build sees: their names and contents.
if (( ${#EXTRA[@]} == 0 )); then
    HASH="$(cd "${DIR}" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | cut -c1-12)"
else
    HASH="$(find "${DIR}" "${EXTRA[@]}" -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | cut -c1-12)"
fi
FILES="${DIR}/${EXTRA[*]:+ ${EXTRA[*]}}"
FILES_MD="$(printf '`%s` ' "${DIR}/" "${EXTRA[@]}" | sed 's/ $//')"

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
    echo "== Building ${REGISTRY}/${NAME}:${TAG} from ${FILES} =="
    # Version and build time also inside the image, if the Dockerfile has the
    # ARGs, so a test run can show which image it used.
    OPTIONS=(--pull --label "runner-kit.source=${REPO}/${DIR}"
        --build-arg "IMAGE_VERSION=${TAG}"
        --build-arg "IMAGE_BUILT=$(date '+%Y-%m-%d %H:%M')")
    # Without the provenance attachment the registry gets one plain manifest.
    if docker buildx version >/dev/null 2>&1; then
        OPTIONS+=(--provenance=false)
    fi
    if (( ${#EXTRA[@]} == 0 )); then
        CONTEXT="${DIR}"
        DOCKERFILE="${DIR}/Dockerfile"
    else
        # A context of only the folder and the files given, with their paths
        # from the repo root.
        CONTEXT="$(mktemp -d)"
        trap 'rm -rf "${CONTEXT}"' EXIT
        tar -cf - "${DIR}" "${EXTRA[@]}" | tar -xf - -C "${CONTEXT}"
        DOCKERFILE="${CONTEXT}/${DIR}/Dockerfile"
    fi
    docker build "${OPTIONS[@]}" -f "${DOCKERFILE}" -t "${REGISTRY}/${NAME}:${TAG}" "${CONTEXT}" \
        || die "building ${NAME} from ${FILES} failed, see the step log"
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
    echo "| Image files | ${FILES_MD} (hash ${HASH}) |"
    echo "| Image | ${STATE} |"
    if (( ${#REMOVED[@]} > 0 )); then
        echo "| Removed old versions | ${REMOVED[*]} |"
    fi
    echo
    echo "_The image is built again only when these files change._"
} >> "${SUMMARY}"

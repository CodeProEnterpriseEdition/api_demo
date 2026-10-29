# Test image of this repo for the API tests: Robot Framework and
# RequestsLibrary on Python 3.13, without a browser.
#
# The test workflows build it on the machine when the files of this folder
# change (job "Test image", .github/scripts/test-image.sh) and run the tests
# in it. Built like a uv project image: uv installs the packages into
# /opt/venv in a build stage, and only that environment is copied into a clean
# runtime image. Pinned: both base images (digest) and every Python package
# (requirements.txt; --strict fails the build if one is missing). Nothing else
# is installed. To update, change a digest or the numbers; the next test run
# builds a new image.

FROM ghcr.io/astral-sh/uv:0.12.13@sha256:b485bd65cc2cf1c9a93b3554012c9c3778cf7b1b5fd3d3096ce9e1226c97e1e6 AS uv

FROM python:3.13.18-slim-trixie@sha256:76baad6037690d6e8c4397fbcaef17bca6f19eecef822b708fe8fa3417d30bb5 AS builder

COPY --from=uv /uv /bin/

ENV UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

COPY requirements.txt /tmp/requirements.txt
RUN uv venv /opt/venv --python /usr/local/bin/python3 \
 && uv pip sync --python /opt/venv/bin/python --strict /tmp/requirements.txt \
 && rm -rf /root/.cache/uv

FROM python:3.13.18-slim-trixie@sha256:76baad6037690d6e8c4397fbcaef17bca6f19eecef822b708fe8fa3417d30bb5 AS runtime

ENV PATH=/opt/venv/bin:$PATH \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv

COPY --from=builder /opt/venv /opt/venv

# Runs as an ordinary user. GitHub Actions jobs give --user root (options),
# because they write to the runner's work folder.
RUN groupadd --gid 1000 robot \
 && useradd --uid 1000 --gid 1000 --create-home --shell /usr/sbin/nologin robot
USER robot

ENTRYPOINT ["robot"]
CMD ["--version"]

# Version and build time inside the image, so a test run can show which image
# it uses (test-image.sh sets the values). Last, so the build cache is kept.
ARG IMAGE_VERSION=unknown
ARG IMAGE_BUILT=unknown
ENV IMAGE_VERSION=${IMAGE_VERSION} \
    IMAGE_BUILT=${IMAGE_BUILT}

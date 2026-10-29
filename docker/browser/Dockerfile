# Test image of this repo: Robot Framework, Browser library (Playwright,
# headless Chromium) and RequestsLibrary.
#
# The test workflows build it on the machine when the files of this folder
# change (job "Test image", .github/scripts/test-image.sh) and run the tests
# in it. Based on Ubuntu 24.04, which Playwright supports. Robot Framework and
# its libraries are pinned in requirements.txt; the base image, Node.js and
# the other packages are the newest ones at build time.

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH=/opt/robot/bin:$PATH

# Python and Node.js 22 (the Browser library needs Node; Ubuntu's own is too old).
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl python3 python3-venv \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

# Robot Framework and libraries, Chromium and the system libraries it needs.
# The system libraries are installed with the Browser library's own Playwright
# (its package-lock), not the newest one from npm, so they match its Chromium.
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m venv /opt/robot \
 && pip install -r /tmp/requirements.txt \
 && rfbrowser init chromium \
 && cd "$(python3 -c 'import Browser, os; print(os.path.dirname(Browser.__file__))')/wrapper" \
 && npx --no playwright install-deps chromium \
 && rm -rf /var/lib/apt/lists/* /root/.npm /tmp/requirements.txt

# Version and build time inside the image, so a test run can show which image
# it uses (test-image.sh sets the values). Last, so the build cache is kept.
ARG IMAGE_VERSION=unknown
ARG IMAGE_BUILT=unknown
ENV IMAGE_VERSION=${IMAGE_VERSION} \
    IMAGE_BUILT=${IMAGE_BUILT}

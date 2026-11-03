FROM ubuntu:24.04

SHELL ["/bin/bash", "-c"]
RUN useradd -ms /bin/bash frogger
WORKDIR /home/frogger
ARG JAVA_VERSION=17

# Environment variables
ENV HOME=/home/frogger
ENV JAVA_HOME=/home/frogger/.sdkman/candidates/java/current
ENV PATH=/home/frogger/.sdkman/candidates/java/current/bin:/home/frogger/.sdkman/candidates/maven/current/bin:/home/frogger/.sdkman/candidates/gradle/current/bin:/usr/local/go/bin:/home/frogger/go/bin:${PATH}
ENV M2_HOME=/home/frogger/.sdkman/candidates/maven/current

# Build time arguments
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=true
ARG DEBIAN_FRONTEND=noninteractive

# OS prerequisites + CVE patches. Single layer with apt cache stripped at the end
# so the cache doesn't bloat the image. --no-install-recommends drops doc/locale extras.
# Also remove the EXTERNALLY-MANAGED marker that Ubuntu 24.04's Python 3.12 ships:
# PEP 668 otherwise blocks `pip install` outside a venv, which is overly restrictive
# for a build-environment image where pipenv/poetry/cryptography must be installed
# system-wide and end users expect `pip` to work for ad-hoc package installs.
RUN apt-get update && apt-get -yq upgrade \
    && apt-get install -yq --no-install-recommends \
         apt-transport-https apt-utils ca-certificates curl git gettext gnupg \
         jq lsb-release python3-pip python3-venv unzip uuid zip \
    && rm -f /usr/lib/python3*/EXTERNALLY-MANAGED \
    && rm -rf /var/lib/apt/lists/*

# Node.js 24 LTS + Yarn + python symlinks. NodeSource repo is set up then nodejs installed
# in the same layer; npm cache is cleaned to keep the layer minimal.
# npm 11.19.1 (bundled with Node 24) ships undici 6.28.0 (CVE-2026-109383); it is replaced
# with the fixed 6.29.1 from the same 6.x line so npm's own API usage stays compatible.
RUN curl -sL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -yq --no-install-recommends nodejs \
    && npm install -g --no-fund yarn \
    && UNDICI_VERSION=6.29.1 \
    && mkdir /tmp/undici-fix \
    && (cd /tmp/undici-fix && npm pack --silent undici@${UNDICI_VERSION} && tar -xzf undici-${UNDICI_VERSION}.tgz) \
    && rm -rf /usr/lib/node_modules/npm/node_modules/undici \
    && mv /tmp/undici-fix/package /usr/lib/node_modules/npm/node_modules/undici \
    && rm -rf /tmp/undici-fix \
    && npm cache clean --force \
    && rm -rf /root/.npm /var/lib/apt/lists/* \
    && ln -sf /usr/bin/pip3 /usr/bin/pip \
    && ln -s /usr/bin/python3 /usr/bin/python

# Pipenv + Poetry. Then explicitly upgrade pip / setuptools / cryptography to
# versions past the known-vulnerable ones (CVE-2025-8869 in pip < 25.3,
# CVE-2025-47273 in setuptools < 78.1.1, multiple CVEs in cryptography < 46.0.3).
# Finally refresh the wheels that virtualenv bundles for venv creation;
# without this, scans flag the old pip/setuptools wheel files inside
# site-packages/virtualenv/seed/wheels/embed/ even after our system upgrade.
# --no-cache-dir avoids baking the wheel cache into the layer.
# --ignore-installed on the upgrade: Ubuntu's apt-packaged python3-pip /
# python3-setuptools / python3-cryptography deliberately omit the RECORD
# metadata, so pip cannot uninstall them to perform an upgrade. Instead we
# install the new versions fresh into /usr/local/lib/python3.12/site-packages/,
# which shadows the apt copies on sys.path.
RUN pip install --no-cache-dir --quiet pipenv poetry \
    && pip install --no-cache-dir --quiet --upgrade --ignore-installed \
         'pip>=25.3' 'setuptools>=78.1.1' 'cryptography>=46.0.3' \
    && virtualenv --upgrade-embed-wheels

# Install Go
RUN curl -fL https://golang.org/dl/go1.26.10.linux-amd64.tar.gz | tar -zxC /usr/local

# Microsoft .NET SDK + Mono toolchain (NuGet, msbuild). Both apt sources are
# registered, then a single apt install + cache strip in the same layer.
# The Mono signing key is fetched from download.mono-project.com (CI-allowlisted)
# and dearmored, since keyserver.ubuntu.com is blocked and apt-key is deprecated.
# Note: Mono's apt repo does not (yet) publish a noble channel; we point at
# stable-focal, which the Mono project keeps backward-compatible for newer
# Ubuntu releases. Re-evaluate if/when Mono publishes a noble channel.
RUN curl -sL https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -o packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb \
    && curl -fsSL https://download.mono-project.com/repo/xamarin.gpg \
         | gpg --dearmor -o /usr/share/keyrings/mono-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/mono-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" \
         > /etc/apt/sources.list.d/mono-official-stable.list \
    && rm /etc/apt/sources.list.d/microsoft-prod.list \
    && apt-get update \
    && apt-get install -yq --no-install-recommends \
         dotnet-sdk-8.0 mono-devel \
    && rm -rf /var/lib/apt/lists/*

# NuGet CLI. The `nuget` apt package from the Mono focal repo bundles NuGet 5.7.0
# (CVE-2024-0057, CVE-2023-29337, CVE-2022-41032), so install a current nuget.exe
# and expose it as `nuget` via a mono wrapper.
ARG NUGET_VERSION=6.14.0
RUN mkdir -p /usr/local/lib/nuget \
    && curl -fsSL https://dist.nuget.org/win-x86-commandline/v${NUGET_VERSION}/nuget.exe -o /usr/local/lib/nuget/nuget.exe \
    && printf '#!/bin/sh\nexec mono /usr/local/lib/nuget/nuget.exe "$@"\n' > /usr/local/bin/nuget \
    && chmod +x /usr/local/bin/nuget

# MSBuild. The Mono `msbuild` apt package (16.10.1) bundles NuGet.Packaging/Common/Protocol 5.7.0
# and Newtonsoft.Json 8.0.3 (CVE-2024-0057 and others), so `msbuild` is served by the
# .NET SDK instead, which ships current NuGet libraries.
RUN printf '#!/bin/sh\nexec dotnet msbuild "$@"\n' > /usr/local/bin/msbuild \
    && chmod +x /usr/local/bin/msbuild

# Java JDK 17 + Maven + Gradle 9.8.2 via SDKMAN. Archives are flushed and SDKMAN
# scratch dirs removed to keep the layer small.
# Gradle 9.8.2 bundles jackson 2.22.3 (CVE-2026-110879), so the jackson jars (core, databind,
# datatype-jdk8/jsr310) are swapped for 2.22.4 with SHA-1 verification against Maven Central.
# jackson-annotations stays at 2.22: annotations are versioned 2.22 in the 2.22.4 BOM.
# Gradle locates these jars by exact name via lib/jackson-*.properties, so those are updated too.
RUN curl -s "https://get.sdkman.io" | bash \
    && source "/home/frogger/.sdkman/bin/sdkman-init.sh" \
    && sdk install java `sdk list java | grep -E "$JAVA_VERSION.*tem" | head -1 | awk '{print $NF}'` && java -version \
    && sdk install maven \
    && sdk install gradle 9.8.2 \
    && GRADLE_LIB=/home/frogger/.sdkman/candidates/gradle/current/lib \
    && JACKSON_VERSION=2.22.4 \
    && JACKSON_REPO=https://repo1.maven.org/maven2/com/fasterxml/jackson \
    && for coord in core/jackson-core core/jackson-databind datatype/jackson-datatype-jdk8 datatype/jackson-datatype-jsr310; do \
         art=${coord#*/}; \
         url="${JACKSON_REPO}/${coord%/*}/${art}/${JACKSON_VERSION}/${art}-${JACKSON_VERSION}.jar"; \
         curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors "$url" -o "/tmp/${art}.jar" \
         && echo "$(curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors "${url}.sha1")  /tmp/${art}.jar" | sha1sum -c - \
         && rm -f "${GRADLE_LIB}/${art}"-[0-9]*.jar \
         && mv "/tmp/${art}.jar" "${GRADLE_LIB}/${art}-${JACKSON_VERSION}.jar" \
         || exit 1; \
       done \
    && sed -i "s/2\.22\.3/${JACKSON_VERSION}/g" "${GRADLE_LIB}"/jackson-*.properties \
    && ! grep -rl '2\.22\.3' "${GRADLE_LIB}" \
    && sdk flush archives \
    && rm -rf /home/frogger/.sdkman/tmp /home/frogger/.sdkman/var/log

# Podman + Docker CLI. Docker apt source uses a signed-by keyring; everything
# installed in one layer with the apt cache stripped.
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
         | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
         > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -yq --no-install-recommends \
         podman docker-ce-cli containerd.io \
    && rm -rf /var/lib/apt/lists/*

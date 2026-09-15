FROM mcr.microsoft.com/dotnet/sdk:10.0

# Exact, tested Microsoft.CST.DevSkim.CLI release baked into the image as the
# default. This is intentionally NOT a floating/latest reference: upstream
# DevSkim CLI publications must never implicitly change the version this
# action runs. Bump this only after verifying the new version installs and
# scans correctly with the .NET runtime above and the arguments used by
# entrypoint.sh, then cut a new action release (see README.md).
ARG DEVSKIM_CLI_VERSION=1.0.90

RUN mkdir /tools

# Explicit, trusted package source (nuget.org only) used for the pinned
# install below and for any runtime devskim-version override.
COPY nuget.config /nuget.config

RUN dotnet tool install --tool-path /tools --version ${DEVSKIM_CLI_VERSION} --configfile /nuget.config Microsoft.CST.DevSkim.Cli \
    && echo "${DEVSKIM_CLI_VERSION}" > /tools/.devskim-baked-version

COPY entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

#!/bin/bash

# $1 is the directory or file to scan
# $2 is if we should crawl archives
# $3 is the output filename
# $4 is the output directory
# $5 is the file globs to ignore
# $6 is the ruleids to exclude
# $7 is the path to a json file for the --options-json argument
# $8 is any additional options
# $9 is an optional exact Microsoft.CST.DevSkim.Cli NuGet version to use
#    instead of the version bundled with this action image.
#
# NOTE: These are positional to preserve compatibility with the existing
# action.yml `args:` list (kept intentionally minimal/unchanged for this
# release). $9 was appended, not inserted, so existing positions 1-8 are
# unaffected. If action.yml's args list is ever reordered, this file's
# positional reads must be updated to match.

set -euo pipefail

# Location of the version bundled/baked into the image at build time, and the
# trusted, explicit NuGet source configuration used for any install. Exposed
# as overridable environment variables so tests can point them at temporary
# locations without touching the real image paths.
BAKED_TOOL_DIR="${DEVSKIM_BAKED_TOOL_DIR:-/tools}"
BAKED_VERSION_FILE="${BAKED_TOOL_DIR}/.devskim-baked-version"
TRUSTED_NUGET_CONFIG="${DEVSKIM_NUGET_CONFIG:-/nuget.config}"
OVERRIDE_BASE_DIR="${DEVSKIM_OVERRIDE_BASE_DIR:-/tmp}"

# Allowlist for the devskim-version input: an exact NuGet stable or
# prerelease version only, e.g. "1.0.90" or "1.0.90-beta.1". This
# intentionally rejects version ranges ("[1.0.90,2.0.0)"), wildcards
# ("1.0.*"), floating aliases ("latest"), whitespace, command line options,
# URLs, and shell metacharacters.
readonly VERSION_REGEX='^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z]+(\.[0-9A-Za-z]+)*)?$'

# Returns success if $1 is an exact, allowlisted NuGet version string.
validate_version() {
    local version="$1"
    [[ "$version" =~ $VERSION_REGEX ]]
}

# Prints the path to the devskim binary to use to stdout, given an optional
# requested version override (may be empty). Fails closed: on any invalid
# input or install failure it prints nothing to stdout, logs an error, and
# returns non-zero. Never silently falls back to the bundled default when an
# override was requested.
resolve_devskim_binary() {
    local requested_version="$1"
    local baked_version=""

    if [ -f "$BAKED_VERSION_FILE" ]; then
        baked_version="$(cat "$BAKED_VERSION_FILE")"
    fi

    if [ -z "$requested_version" ]; then
        echo "${BAKED_TOOL_DIR}/devskim"
        return 0
    fi

    if ! validate_version "$requested_version"; then
        echo "::error::Invalid devskim-version '${requested_version}'. Provide an exact published NuGet version such as 1.0.90 or 1.0.90-beta.1. Version ranges, wildcards, 'latest', and other values are not supported." >&2
        return 1
    fi

    if [ "$requested_version" = "$baked_version" ]; then
        # Requested version matches what is already baked into the image;
        # avoid a redundant runtime install.
        echo "${BAKED_TOOL_DIR}/devskim"
        return 0
    fi

    local override_dir
    # Use mktemp to create a fresh, unpredictable, mode-0700 directory rather
    # than a fixed path derived from the version string, so a pre-created
    # symlink or file at a predictable shared /tmp path cannot be used to
    # tamper with the isolated install destination.
    if ! override_dir="$(mktemp -d "${OVERRIDE_BASE_DIR%/}/devskim-override-XXXXXXXXXX")"; then
        echo "::error::Failed to create an isolated tool directory for devskim-version '${requested_version}'." >&2
        return 1
    fi

    echo "Installing DevSkim CLI ${requested_version} from nuget.org into an isolated tool directory..." >&2
    if ! dotnet tool install --tool-path "$override_dir" --version "$requested_version" --configfile "$TRUSTED_NUGET_CONFIG" Microsoft.CST.DevSkim.Cli >&2; then
        echo "::error::Failed to install requested devskim-version '${requested_version}'. Confirm the version exists on nuget.org and is compatible with the .NET runtime used by this action." >&2
        return 1
    fi

    echo "${override_dir}/devskim"
}

main() {
    local ScanTarget OutputDirectory OptionsJsonArg Opts Idopts DevSkimBin

    if [ "$1" = "GITHUB_WORKSPACE" ]; then
        ScanTarget=$GITHUB_WORKSPACE
    else
        ScanTarget=$GITHUB_WORKSPACE/$1
    fi

    if [ "$4" = "GITHUB_WORKSPACE" ]; then
        OutputDirectory=$GITHUB_WORKSPACE
    else
        OutputDirectory=$GITHUB_WORKSPACE/$4
    fi

    if [ -z "${7:-}" ]; then
        OptionsJsonArg=""
    else
        OptionsJsonArg="--options-json $GITHUB_WORKSPACE/$7"
    fi

    Opts=""
    if [ "${2:-}" = "true" ]; then
        Opts="-c"
    fi

    if [ -z "${6:-}" ]; then
        Idopts=""
    else
        Idopts="--ignore-rule-ids $6"
    fi

    if ! DevSkimBin="$(resolve_devskim_binary "${9:-}")"; then
        exit 1
    fi
    echo "Using DevSkim CLI at ${DevSkimBin}: $("$DevSkimBin" --version 2>&1 || echo unknown)"

    # Prevent glob expansion, fix ignore-globs parsing
    set -o noglob

    "$DevSkimBin" analyze --source-code "$ScanTarget" --output-file "$OutputDirectory/$3" $8 $Opts --ignore-globs $5 $Idopts $OptionsJsonArg
}

# Only run main when executed directly, so this file can be sourced by tests
# to exercise validate_version and resolve_devskim_binary in isolation.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

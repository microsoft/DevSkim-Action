#!/bin/bash
#
# Unit tests for the DevSkim CLI version resolution logic in entrypoint.sh.
# These tests source entrypoint.sh (which guards its `main` invocation behind
# a source-vs-exec check) and exercise the resolve_devskim_binary function
# directly, mocking `dotnet` so no network access or real DevSkim CLI install
# is required.
#
# Usage: bash tests/entrypoint_test.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILURES=0
TOTAL=0

pass() {
    TOTAL=$((TOTAL + 1))
    echo "ok - $1"
}

fail() {
    TOTAL=$((TOTAL + 1))
    FAILURES=$((FAILURES + 1))
    echo "not ok - $1"
}

assert_success() {
    local desc="$1"
    shift
    if "$@" >/tmp/entrypoint_test_out 2>/tmp/entrypoint_test_err; then
        pass "$desc"
    else
        fail "$desc (exit $?, stderr: $(cat /tmp/entrypoint_test_err))"
    fi
}

assert_failure() {
    local desc="$1"
    shift
    if "$@" >/tmp/entrypoint_test_out 2>/tmp/entrypoint_test_err; then
        fail "$desc (expected failure but succeeded)"
    else
        pass "$desc"
    fi
}

# Track whether the mocked dotnet was invoked, and whether it should succeed.
DOTNET_CALL_COUNT_FILE="$(mktemp)"
echo 0 > "$DOTNET_CALL_COUNT_FILE"
DOTNET_SHOULD_FAIL=0

dotnet() {
    local count
    count="$(cat "$DOTNET_CALL_COUNT_FILE")"
    echo $((count + 1)) > "$DOTNET_CALL_COUNT_FILE"

    if [ "$DOTNET_SHOULD_FAIL" -eq 1 ]; then
        echo "mock dotnet: simulated install failure" >&2
        return 1
    fi

    # Simulate `dotnet tool install --tool-path DIR ... Microsoft.CST.DevSkim.Cli`
    local tool_path=""
    local args=("$@")
    for i in "${!args[@]}"; do
        if [ "${args[$i]}" = "--tool-path" ]; then
            tool_path="${args[$((i + 1))]}"
        fi
    done
    if [ -n "$tool_path" ]; then
        mkdir -p "$tool_path"
        cat > "$tool_path/devskim" <<'EOF'
#!/bin/bash
echo "mock-devskim"
EOF
        chmod +x "$tool_path/devskim"
    fi
    return 0
}

dotnet_call_count() {
    cat "$DOTNET_CALL_COUNT_FILE"
}

# Source entrypoint.sh; because BASH_SOURCE[0] != $0 when sourced, main() is
# not invoked automatically.
# shellcheck disable=SC1091
source "$REPO_ROOT/entrypoint.sh"

echo "=== resolve_devskim_binary: behavior ==="

# Isolated fixture directories per scenario to avoid cross-test interference.
setup_fixture() {
    export DEVSKIM_BAKED_TOOL_DIR
    export DEVSKIM_OVERRIDE_BASE_DIR
    DEVSKIM_BAKED_TOOL_DIR="$(mktemp -d)"
    DEVSKIM_OVERRIDE_BASE_DIR="$(mktemp -d)"
    BAKED_TOOL_DIR="$DEVSKIM_BAKED_TOOL_DIR"
    BAKED_VERSION_FILE="${BAKED_TOOL_DIR}/.devskim-baked-version"
    OVERRIDE_BASE_DIR="$DEVSKIM_OVERRIDE_BASE_DIR"
    mkdir -p "$BAKED_TOOL_DIR"
    echo -n "1.0.90" > "$BAKED_VERSION_FILE"
    cat > "${BAKED_TOOL_DIR}/devskim" <<'EOF'
#!/bin/bash
echo "baked-devskim"
EOF
    chmod +x "${BAKED_TOOL_DIR}/devskim"
}

# 1. Omitted/empty version -> baked binary, no install invoked.
setup_fixture
echo 0 > "$DOTNET_CALL_COUNT_FILE"
DOTNET_SHOULD_FAIL=0
out="$(resolve_devskim_binary "")"
if [ "$out" = "${BAKED_TOOL_DIR}/devskim" ] && [ "$(dotnet_call_count)" -eq 0 ]; then
    pass "empty version resolves to baked binary without invoking dotnet"
else
    fail "empty version resolves to baked binary without invoking dotnet (got '$out', calls $(dotnet_call_count))"
fi

# 2. Requested version identical to baked version -> baked binary, no install.
setup_fixture
echo 0 > "$DOTNET_CALL_COUNT_FILE"
DOTNET_SHOULD_FAIL=0
out="$(resolve_devskim_binary "1.0.90")"
if [ "$out" = "${BAKED_TOOL_DIR}/devskim" ] && [ "$(dotnet_call_count)" -eq 0 ]; then
    pass "same-as-baked version bypasses runtime install"
else
    fail "same-as-baked version bypasses runtime install (got '$out', calls $(dotnet_call_count))"
fi

# 3. Valid alternate exact version (downgrade) -> isolated dir, install invoked once.
setup_fixture
echo 0 > "$DOTNET_CALL_COUNT_FILE"
DOTNET_SHOULD_FAIL=0
out="$(resolve_devskim_binary "1.0.70")"
if [[ "$out" == "${OVERRIDE_BASE_DIR}"/devskim-override-*/devskim ]] && [ "$(dotnet_call_count)" -eq 1 ] && [ -x "$out" ]; then
    pass "valid alternate (downgrade) version installs into isolated directory"
else
    fail "valid alternate (downgrade) version installs into isolated directory (got '$out', calls $(dotnet_call_count))"
fi

# 3b. Installing the same alternate version twice creates two distinct
# unpredictable directories rather than reusing a fixed, guessable path.
out2="$(resolve_devskim_binary "1.0.70")"
if [ "$out2" != "$out" ] && [ "$(dotnet_call_count)" -eq 2 ] && [ -x "$out2" ]; then
    pass "repeated override installs use fresh unpredictable directories"
else
    fail "repeated override installs use fresh unpredictable directories (first '$out', second '$out2', calls $(dotnet_call_count))"
fi

# 4. Unusable input (shell metacharacters) is passed through to NuGet as a
# single argument; NuGet rejects it and the failure propagates rather than
# the value being interpreted by the shell.
setup_fixture
echo 0 > "$DOTNET_CALL_COUNT_FILE"
DOTNET_SHOULD_FAIL=1
if out="$(resolve_devskim_binary "1.0.90; rm -rf /tmp/should-not-run")"; then
    fail "unusable version input fails without being interpreted by the shell (unexpectedly succeeded: '$out')"
elif [ -e /tmp/should-not-run ] || [ "$(dotnet_call_count)" -ne 1 ]; then
    fail "unusable version input fails without being interpreted by the shell (calls $(dotnet_call_count))"
else
    pass "unusable version input fails without being interpreted by the shell"
fi
DOTNET_SHOULD_FAIL=0

# 5. Prerelease versions with hyphenated identifiers are handed to NuGet unchanged.
setup_fixture
echo 0 > "$DOTNET_CALL_COUNT_FILE"
DOTNET_SHOULD_FAIL=0
out="$(resolve_devskim_binary "1.2.3-nightly-build")"
if [[ "$out" == "${OVERRIDE_BASE_DIR}"/devskim-override-*/devskim ]] && [ "$(dotnet_call_count)" -eq 1 ]; then
    pass "hyphenated prerelease version is passed through to NuGet"
else
    fail "hyphenated prerelease version is passed through to NuGet (got '$out', calls $(dotnet_call_count))"
fi

# 6. Valid but nonexistent/incompatible version -> install failure propagates, no fallback to baked binary.
setup_fixture
echo 0 > "$DOTNET_CALL_COUNT_FILE"
DOTNET_SHOULD_FAIL=1
if out="$(resolve_devskim_binary "9.9.9")"; then
    fail "failed install does not silently fall back to bundled binary (unexpectedly succeeded: '$out')"
else
    pass "failed install does not silently fall back to bundled binary"
fi
DOTNET_SHOULD_FAIL=0

echo
echo "$((TOTAL - FAILURES))/$TOTAL tests passed"
if [ "$FAILURES" -ne 0 ]; then
    exit 1
fi

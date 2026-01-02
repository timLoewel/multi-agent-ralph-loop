#!/usr/bin/env bash
# uninstall.sh - Multi-Agent Ralph Wiggum Uninstaller
# Removes ralph CLI and all associated configurations

set -euo pipefail

VERSION="2.14.0"

# Installation directories
INSTALL_DIR="${HOME}/.local/bin"
RALPH_DIR="${HOME}/.ralph"
CLAUDE_DIR="${HOME}/.claude"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Ralph agents to remove
RALPH_AGENTS=(
    "orchestrator.md"
    "security-auditor.md"
    "code-reviewer.md"
    "test-architect.md"
    "debugger.md"
    "refactorer.md"
    "docs-writer.md"
    "frontend-reviewer.md"
    "minimax-reviewer.md"
)

# Ralph commands to remove
RALPH_COMMANDS=(
    "orchestrator.md"
    "clarify.md"
    "full-review.md"
    "parallel.md"
    "security.md"
    "bugs.md"
    "unit-tests.md"
    "refactor.md"
    "research.md"
    "minimax.md"
    "gates.md"
    "loop.md"
    "adversarial.md"
    "retrospective.md"
    "improvements.md"
)

# Ralph skills to remove
RALPH_SKILLS=(
    "ask-questions-if-underspecified"
    "task-classifier"
    "retrospective"
)

# ═══════════════════════════════════════════════════════════════════════════════
# REMOVE CLI SCRIPTS
# ═══════════════════════════════════════════════════════════════════════════════
remove_scripts() {
    log_info "Removing CLI scripts..."

    [ -f "$INSTALL_DIR/ralph" ] && rm -f "$INSTALL_DIR/ralph" && log_success "Removed ralph"
    [ -f "$INSTALL_DIR/mmc" ] && rm -f "$INSTALL_DIR/mmc" && log_success "Removed mmc"
}

# ═══════════════════════════════════════════════════════════════════════════════
# REMOVE CLAUDE COMPONENTS
# ═══════════════════════════════════════════════════════════════════════════════
remove_claude_components() {
    log_info "Removing Claude Code components..."

    # Remove agents
    for agent in "${RALPH_AGENTS[@]}"; do
        if [ -f "${CLAUDE_DIR}/agents/${agent}" ]; then
            rm -f "${CLAUDE_DIR}/agents/${agent}"
        fi
    done
    log_success "Removed Ralph agents"

    # Remove commands
    for cmd in "${RALPH_COMMANDS[@]}"; do
        if [ -f "${CLAUDE_DIR}/commands/${cmd}" ]; then
            rm -f "${CLAUDE_DIR}/commands/${cmd}"
        fi
    done
    log_success "Removed Ralph commands"

    # Remove skills
    for skill in "${RALPH_SKILLS[@]}"; do
        if [ -d "${CLAUDE_DIR}/skills/${skill}" ]; then
            rm -rf "${CLAUDE_DIR}/skills/${skill}"
        fi
    done
    log_success "Removed Ralph skills"

    # Remove hooks
    [ -f "${CLAUDE_DIR}/hooks/quality-gates.sh" ] && rm -f "${CLAUDE_DIR}/hooks/quality-gates.sh"
    [ -f "${CLAUDE_DIR}/hooks/git-safety-guard.py" ] && rm -f "${CLAUDE_DIR}/hooks/git-safety-guard.py"
    log_success "Removed Ralph hooks (quality-gates.sh, git-safety-guard.py)"
}

# ═══════════════════════════════════════════════════════════════════════════════
# REMOVE RALPH DATA
# ═══════════════════════════════════════════════════════════════════════════════
remove_ralph_data() {
    local KEEP_BACKUPS="${1:-false}"

    if [ "$KEEP_BACKUPS" = "true" ]; then
        log_info "Removing Ralph data (keeping backups)..."
        rm -rf "${RALPH_DIR}/config"
        rm -rf "${RALPH_DIR}/logs"
        rm -rf "${RALPH_DIR}/improvements/pending.md"
        log_success "Ralph data removed (backups preserved in ${RALPH_DIR}/backups)"
    else
        log_info "Removing all Ralph data..."
        rm -rf "$RALPH_DIR"
        log_success "All Ralph data removed"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# REMOVE CODEX CONFIG
# ═══════════════════════════════════════════════════════════════════════════════
remove_codex_config() {
    log_info "Removing Codex CLI config..."

    [ -f "${HOME}/.codex/instructions.md" ] && rm -f "${HOME}/.codex/instructions.md"
    [ -d "${HOME}/.codex/skills" ] && rm -rf "${HOME}/.codex/skills"

    log_success "Codex config removed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# REMOVE GEMINI CONFIG
# ═══════════════════════════════════════════════════════════════════════════════
remove_gemini_config() {
    log_info "Removing Gemini CLI config..."

    [ -f "${HOME}/.gemini/GEMINI.md" ] && rm -f "${HOME}/.gemini/GEMINI.md"

    log_success "Gemini config removed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# CLEAN SHELL CONFIG
# ═══════════════════════════════════════════════════════════════════════════════
clean_shell_config() {
    log_info "Cleaning shell configuration..."

    local SHELL_RC=""
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_RC="$HOME/.bashrc"
    fi

    if [ -n "$SHELL_RC" ] && grep -q "# Ralph Wiggum" "$SHELL_RC" 2>/dev/null; then
        # Create backup
        cp "$SHELL_RC" "${SHELL_RC}.ralph-backup"

        # Remove Ralph section (between the header and the end of aliases block)
        sed -i.bak '/# ═.*Ralph Wiggum/,/^alias mmlight=/d' "$SHELL_RC" 2>/dev/null || \
        sed -i '' '/# ═.*Ralph Wiggum/,/^alias mmlight=/d' "$SHELL_RC" 2>/dev/null || \
        log_warn "Could not automatically remove shell aliases"

        # Also try simpler pattern
        sed -i.bak '/# Ralph Wiggum/,/alias mmlight/d' "$SHELL_RC" 2>/dev/null || \
        sed -i '' '/# Ralph Wiggum/,/alias mmlight/d' "$SHELL_RC" 2>/dev/null || true

        rm -f "${SHELL_RC}.bak" 2>/dev/null || true

        log_success "Shell aliases removed (backup: ${SHELL_RC}.ralph-backup)"
    else
        log_info "No shell aliases found to remove"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════
main() {
    local KEEP_BACKUPS=false
    local FULL_UNINSTALL=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --keep-backups)
                KEEP_BACKUPS=true
                shift
                ;;
            --full)
                FULL_UNINSTALL=true
                shift
                ;;
            --help|-h)
                echo "Usage: uninstall.sh [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --keep-backups   Keep backup files in ~/.ralph/backups"
                echo "  --full           Also remove Codex and Gemini configs"
                echo "  --help           Show this help"
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done

    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "  🎭 Multi-Agent Ralph Wiggum v${VERSION} - Uninstaller"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "  This will remove:"
    echo "    • ralph and mmc CLI from ~/.local/bin/"
    echo "    • Ralph agents from ~/.claude/agents/"
    echo "    • Ralph commands from ~/.claude/commands/"
    echo "    • Ralph skills from ~/.claude/skills/"
    echo "    • Ralph hooks from ~/.claude/hooks/"
    echo "    • Ralph data from ~/.ralph/"
    echo "    • Shell aliases from ~/.zshrc or ~/.bashrc"

    if [ "$FULL_UNINSTALL" = "true" ]; then
        echo "    • Codex config from ~/.codex/"
        echo "    • Gemini config from ~/.gemini/"
    fi

    if [ "$KEEP_BACKUPS" = "true" ]; then
        echo ""
        echo "  ${YELLOW}Backups will be preserved${NC}"
    fi

    echo ""
    read -p "  Continue? [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "  Aborted."
        exit 0
    fi

    echo ""

    remove_scripts
    remove_claude_components
    remove_ralph_data "$KEEP_BACKUPS"

    if [ "$FULL_UNINSTALL" = "true" ]; then
        remove_codex_config
        remove_gemini_config
    fi

    clean_shell_config

    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "  ${GREEN}✅ UNINSTALL COMPLETE${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "  Don't forget to reload your shell:"
    echo "    source ~/.zshrc  (or ~/.bashrc)"
    echo ""

    if [ "$KEEP_BACKUPS" = "true" ]; then
        echo "  Your backups are preserved in: ${RALPH_DIR}/backups/"
        echo ""
    fi

    echo "═══════════════════════════════════════════════════════════════════════════════"
}

main "$@"

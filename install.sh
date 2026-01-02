#!/usr/bin/env bash
# install.sh - Multi-Agent Ralph Wiggum v2.14 Global Installer
# Installs ralph CLI globally and integrates with Claude Code

set -euo pipefail

VERSION="2.14.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Installation directories
INSTALL_DIR="${HOME}/.local/bin"
RALPH_DIR="${HOME}/.ralph"
CLAUDE_DIR="${HOME}/.claude"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCY CHECK
# ═══════════════════════════════════════════════════════════════════════════════
check_dependencies() {
    echo ""
    log_info "Checking dependencies..."

    local MISSING=()
    local OPTIONAL_MISSING=()

    # Required
    command -v jq &>/dev/null || MISSING+=("jq")
    command -v curl &>/dev/null || MISSING+=("curl")

    # Optional but recommended
    command -v claude &>/dev/null || OPTIONAL_MISSING+=("claude (Claude Code CLI)")
    command -v codex &>/dev/null || OPTIONAL_MISSING+=("codex (Codex CLI)")
    command -v gemini &>/dev/null || OPTIONAL_MISSING+=("gemini (Gemini CLI)")

    # Language-specific (optional)
    command -v npx &>/dev/null || OPTIONAL_MISSING+=("npx (Node.js - for TypeScript/ESLint)")
    command -v pyright &>/dev/null || OPTIONAL_MISSING+=("pyright (Python type checker)")
    command -v ruff &>/dev/null || OPTIONAL_MISSING+=("ruff (Python linter)")

    if [ ${#MISSING[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${MISSING[*]}"
        echo ""
        echo "  Install them with:"
        echo "    brew install ${MISSING[*]}"
        echo ""
        exit 1
    fi

    log_success "Required dependencies OK"

    if [ ${#OPTIONAL_MISSING[@]} -gt 0 ]; then
        log_warn "Optional dependencies not found:"
        for dep in "${OPTIONAL_MISSING[@]}"; do
            echo "    - $dep"
        done
        echo ""
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# BACKUP EXISTING CONFIG
# ═══════════════════════════════════════════════════════════════════════════════
backup_existing() {
    local BACKUP_DIR="${RALPH_DIR}/backups/$(date +%Y%m%d_%H%M%S)"

    if [ -d "${CLAUDE_DIR}/agents" ] || [ -d "${CLAUDE_DIR}/commands" ]; then
        log_info "Backing up existing Claude Code config..."
        mkdir -p "$BACKUP_DIR"

        [ -d "${CLAUDE_DIR}/agents" ] && cp -r "${CLAUDE_DIR}/agents" "$BACKUP_DIR/" 2>/dev/null || true
        [ -d "${CLAUDE_DIR}/commands" ] && cp -r "${CLAUDE_DIR}/commands" "$BACKUP_DIR/" 2>/dev/null || true
        [ -d "${CLAUDE_DIR}/skills" ] && cp -r "${CLAUDE_DIR}/skills" "$BACKUP_DIR/" 2>/dev/null || true
        [ -d "${CLAUDE_DIR}/hooks" ] && cp -r "${CLAUDE_DIR}/hooks" "$BACKUP_DIR/" 2>/dev/null || true
        [ -f "${CLAUDE_DIR}/settings.json" ] && cp "${CLAUDE_DIR}/settings.json" "$BACKUP_DIR/" 2>/dev/null || true

        log_success "Backup saved to: $BACKUP_DIR"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# CREATE DIRECTORIES
# ═══════════════════════════════════════════════════════════════════════════════
create_directories() {
    log_info "Creating directories..."

    mkdir -p "$INSTALL_DIR"
    mkdir -p "$RALPH_DIR"/{config,improvements/backups,logs}
    mkdir -p "$CLAUDE_DIR"/{agents,commands,skills,hooks}

    log_success "Directories created"
}

# ═══════════════════════════════════════════════════════════════════════════════
# INSTALL CLI SCRIPTS
# ═══════════════════════════════════════════════════════════════════════════════
install_scripts() {
    log_info "Installing CLI scripts..."

    # Copy ralph and mmc
    cp "${SCRIPT_DIR}/scripts/ralph" "$INSTALL_DIR/ralph"
    cp "${SCRIPT_DIR}/scripts/mmc" "$INSTALL_DIR/mmc"

    # Make executable
    chmod +x "$INSTALL_DIR/ralph"
    chmod +x "$INSTALL_DIR/mmc"

    log_success "CLI scripts installed to $INSTALL_DIR"
}

# ═══════════════════════════════════════════════════════════════════════════════
# INSTALL CLAUDE CODE COMPONENTS
# ═══════════════════════════════════════════════════════════════════════════════
install_claude_components() {
    log_info "Installing Claude Code components..."

    # Agents
    if [ -d "${SCRIPT_DIR}/.claude/agents" ]; then
        cp -r "${SCRIPT_DIR}/.claude/agents/"* "${CLAUDE_DIR}/agents/" 2>/dev/null || true
        log_success "Agents installed ($(ls -1 "${CLAUDE_DIR}/agents/" 2>/dev/null | wc -l | tr -d ' ') files)"
    fi

    # Commands
    if [ -d "${SCRIPT_DIR}/.claude/commands" ]; then
        cp -r "${SCRIPT_DIR}/.claude/commands/"* "${CLAUDE_DIR}/commands/" 2>/dev/null || true
        log_success "Commands installed ($(ls -1 "${CLAUDE_DIR}/commands/" 2>/dev/null | wc -l | tr -d ' ') files)"
    fi

    # Skills
    if [ -d "${SCRIPT_DIR}/.claude/skills" ]; then
        cp -r "${SCRIPT_DIR}/.claude/skills/"* "${CLAUDE_DIR}/skills/" 2>/dev/null || true
        log_success "Skills installed"
    fi

    # Hooks (with proper permissions)
    if [ -d "${SCRIPT_DIR}/.claude/hooks" ]; then
        cp -r "${SCRIPT_DIR}/.claude/hooks/"* "${CLAUDE_DIR}/hooks/" 2>/dev/null || true
        # Make all hook scripts executable (both .sh and .py)
        chmod +x "${CLAUDE_DIR}/hooks/"*.sh 2>/dev/null || true
        chmod +x "${CLAUDE_DIR}/hooks/"*.py 2>/dev/null || true
        log_success "Hooks installed:"
        log_success "  - git-safety-guard.py (blocks destructive git commands)"
        log_success "  - quality-gates.sh (9-language validation)"
    fi

    # Install settings.json (with PreToolUse hook for git safety)
    if [ -f "${SCRIPT_DIR}/.claude/settings.json" ]; then
        cp "${SCRIPT_DIR}/.claude/settings.json" "${CLAUDE_DIR}/settings.json"
        log_success "Settings installed (git-safety-guard ACTIVE by default)"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# INSTALL CODEX CONFIG
# ═══════════════════════════════════════════════════════════════════════════════
install_codex_config() {
    if [ -d "${SCRIPT_DIR}/.codex" ]; then
        log_info "Installing Codex CLI config..."
        mkdir -p "${HOME}/.codex/skills"
        cp -r "${SCRIPT_DIR}/.codex/"* "${HOME}/.codex/" 2>/dev/null || true
        log_success "Codex config installed"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# INSTALL GEMINI CONFIG
# ═══════════════════════════════════════════════════════════════════════════════
install_gemini_config() {
    if [ -d "${SCRIPT_DIR}/.gemini" ]; then
        log_info "Installing Gemini CLI config..."
        mkdir -p "${HOME}/.gemini"
        cp -r "${SCRIPT_DIR}/.gemini/"* "${HOME}/.gemini/" 2>/dev/null || true
        log_success "Gemini config installed"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# INSTALL CONFIG FILES
# ═══════════════════════════════════════════════════════════════════════════════
install_config() {
    log_info "Installing configuration..."

    # Copy models.json
    cp "${SCRIPT_DIR}/config/models.json" "${RALPH_DIR}/config/"

    log_success "Configuration installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURE SHELL
# ═══════════════════════════════════════════════════════════════════════════════
configure_shell() {
    log_info "Configuring shell..."

    local SHELL_RC=""
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_RC="$HOME/.bashrc"
    fi

    if [ -n "$SHELL_RC" ]; then
        if ! grep -q "# Ralph Wiggum" "$SHELL_RC" 2>/dev/null; then
            cat >> "$SHELL_RC" << 'RCEOF'

# ═══════════════════════════════════════════════════════════════════════════════
# Ralph Wiggum v2.14 - Multi-Agent Orchestration
# ═══════════════════════════════════════════════════════════════════════════════
export PATH="$HOME/.local/bin:$PATH"

# Ralph aliases
alias rh='ralph'
alias rho='ralph orch'
alias rhr='ralph review'
alias rhp='ralph parallel'
alias rhs='ralph security'
alias rhb='ralph bugs'
alias rhu='ralph unit-tests'
alias rhf='ralph refactor'
alias rhres='ralph research'
alias rhm='ralph minimax'
alias rhg='ralph gates'
alias rha='ralph adversarial'
alias rhl='ralph loop'
alias rhc='ralph clarify'
alias rhret='ralph retrospective'
alias rhi='ralph improvements'

# MiniMax aliases
alias mm='mmc'
alias mml='mmc --loop 30'
alias mmlight='mmc --lightning'
RCEOF
            log_success "Shell aliases added to $SHELL_RC"
        else
            log_info "Shell aliases already configured"
        fi
    else
        log_warn "No .zshrc or .bashrc found - add PATH manually"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# VERIFY INSTALLATION
# ═══════════════════════════════════════════════════════════════════════════════
verify_installation() {
    log_info "Verifying installation..."

    local ERRORS=0

    [ -x "$INSTALL_DIR/ralph" ] && log_success "ralph CLI installed" || { log_error "ralph not found"; ((ERRORS++)); }
    [ -x "$INSTALL_DIR/mmc" ] && log_success "mmc CLI installed" || { log_error "mmc not found"; ((ERRORS++)); }
    [ -d "${CLAUDE_DIR}/agents" ] && log_success "Agents directory OK" || { log_error "Agents missing"; ((ERRORS++)); }
    [ -d "${CLAUDE_DIR}/commands" ] && log_success "Commands directory OK" || { log_error "Commands missing"; ((ERRORS++)); }
    [ -x "${CLAUDE_DIR}/hooks/git-safety-guard.py" ] && log_success "Git Safety Guard installed (ACTIVE)" || log_warn "Git Safety Guard may need chmod +x"
    [ -x "${CLAUDE_DIR}/hooks/quality-gates.sh" ] && log_success "Quality Gates installed" || log_warn "Quality Gates may need chmod +x"
    [ -f "${CLAUDE_DIR}/settings.json" ] && log_success "Settings with hooks configured" || log_warn "Settings.json missing"

    return $ERRORS
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════
main() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "  🎭 Multi-Agent Ralph Wiggum v${VERSION} - Global Installer"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "  This will install:"
    echo "    • ralph CLI to ~/.local/bin/"
    echo "    • mmc (MiniMax wrapper) to ~/.local/bin/"
    echo "    • 9 agents to ~/.claude/agents/"
    echo "    • 15 commands to ~/.claude/commands/"
    echo "    • 3 skills to ~/.claude/skills/"
    echo "    • Git Safety Guard (blocks destructive commands) - ALWAYS ACTIVE"
    echo "    • Quality Gates (9-language validation) - Manual via 'ralph gates'"
    echo "    • Shell aliases to ~/.zshrc or ~/.bashrc"
    echo ""

    read -p "  Continue? [Y/n] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]?$ ]]; then
        echo "  Aborted."
        exit 0
    fi

    echo ""

    check_dependencies
    backup_existing
    create_directories
    install_scripts
    install_claude_components
    install_codex_config
    install_gemini_config
    install_config
    configure_shell

    echo ""

    if verify_installation; then
        echo ""
        echo "═══════════════════════════════════════════════════════════════════════════════"
        echo "  ${GREEN}✅ INSTALLATION COMPLETE${NC}"
        echo "═══════════════════════════════════════════════════════════════════════════════"
        echo ""
        echo "  Next steps:"
        echo ""
        echo "  1. Reload your shell:"
        echo "     ${CYAN}source ~/.zshrc${NC}  (or ~/.bashrc)"
        echo ""
        echo "  2. (Optional) Configure MiniMax for 2-4x iterations:"
        echo "     ${CYAN}mmc --setup${NC}"
        echo ""
        echo "  3. Start using Ralph:"
        echo "     ${CYAN}ralph help${NC}"
        echo "     ${CYAN}ralph orch \"Your task here\"${NC}"
        echo ""
        echo "  4. Run quality gates manually when needed:"
        echo "     ${CYAN}ralph gates${NC}"
        echo ""
        echo "  To uninstall:"
        echo "     ${CYAN}ralph --uninstall${NC}  or  ${CYAN}./uninstall.sh${NC}"
        echo ""
        echo "═══════════════════════════════════════════════════════════════════════════════"
    else
        echo ""
        log_error "Installation completed with errors. Check messages above."
        exit 1
    fi
}

main "$@"

# Multi-Agent Ralph v2.14

Orchestration with adversarial validation, self-improvement, and 9-language quality gates.

## Mandatory Flow

```
1. /clarify     → MUST_HAVE / NICE_TO_HAVE questions
2. /classify    → Complexity 1-10
3. @orchestrator → Delegate to subagents
4. ralph gates  → Quality gates (9 languages)
5. /adversarial → 2/3 consensus (critical code)
6. /retrospective → Propose improvements
7. VERIFIED_DONE
```

## Iteration Limits

| Model | Max Iter | Use Case |
|-------|----------|----------|
| Claude | **15** | Complex reasoning |
| MiniMax M2.1 | **30** | Standard (2x) |
| MiniMax-lightning | **60** | Extended (4x) |

## Quick Commands

```bash
# CLI
ralph orch "task"         # Full orchestration
ralph adversarial src/    # 2/3 consensus
ralph parallel src/       # 6 subagents
ralph security src/       # Security audit
ralph bugs src/           # Bug hunting
ralph gates               # Quality gates
ralph loop "task"         # Loop (15 iter)
ralph loop --mmc "task"   # Loop (30 iter)
ralph retrospective       # Self-improvement

# MiniMax
mmc                       # Launch with MiniMax
mmc --loop 30 "task"      # Extended loop

# Slash Commands
/orchestrator /clarify /full-review /parallel
/security /bugs /unit-tests /refactor
/research /minimax /gates /loop
/adversarial /retrospective /improvements
```

## Agents (9)

```bash
@orchestrator    # Opus - Coordinator
@security-auditor
@code-reviewer
@test-architect
@debugger        # Opus
@refactorer
@docs-writer
@frontend-reviewer  # Opus
@minimax-reviewer   # Fallback
```

## Aliases

```bash
rh=ralph rho=orch rhr=review rhs=security
rhb=bugs rhu=unit-tests rhg=gates rha=adversarial
mm=mmc mml="mmc --loop 30"
```

## Completion

`VERIFIED_DONE` = clarified + classified + implemented + gates passed + adversarial passed (if critical) + retrospective done

#!/bin/bash

# Agent Box Setup Verification Script
# Run this to verify all components are properly installed

echo "========================================="
echo "  Agent Box Setup Verification"
echo "========================================="
echo ""

# Load nvm and SDKMAN in this non-interactive script when present.
[ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh"
[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && . "$HOME/.sdkman/bin/sdkman-init.sh"

# Agent Binaries
echo "=== Agent Binaries ==="
claude --version 2>/dev/null && echo "✓ Claude Code installed" || echo "✗ Claude Code missing"
agent --version 2>/dev/null && echo "✓ Cursor CLI Agent installed" || echo "✗ Cursor CLI Agent missing"
cursor --version 2>/dev/null | head -1 && echo "✓ Cursor IDE installed" || echo "✗ Cursor IDE missing"
echo ""

# Agent Configuration
echo "=== Agent Configuration ==="
test -L ~/AGENTS.md && echo "✓ ~/AGENTS.md symlink exists" || echo "✗ ~/AGENTS.md missing"
test -L ~/CLAUDE.md && echo "✓ ~/CLAUDE.md symlink exists" || echo "✗ ~/CLAUDE.md missing"
test -L ~/.claude/settings.json && echo "✓ Claude settings linked" || echo "✗ Claude settings missing"
echo ""

# Rules
echo "=== Rules ==="
claude_rules=$(ls ~/.claude/rules/ 2>/dev/null | wc -l)
cursor_rules=$(ls ~/.cursor/rules/ 2>/dev/null | wc -l)
echo "Claude rules: $claude_rules files"
echo "Cursor rules: $cursor_rules files"
if [ "$claude_rules" -gt 0 ] && [ "$cursor_rules" -gt 0 ]; then
    echo "✓ Rules configured"
else
    echo "✗ Rules missing or incomplete"
fi
echo ""

# Skills
echo "=== Skills ==="
claude_skills=$(ls ~/.claude/skills/ 2>/dev/null | wc -l)
cursor_skills=$(ls ~/.cursor/skills/ 2>/dev/null | wc -l)
echo "Claude skills: $claude_skills directories"
echo "Cursor skills: $cursor_skills directories"
if [ "$claude_skills" -gt 0 ] && [ "$cursor_skills" -gt 0 ]; then
    echo "✓ Skills configured"
else
    echo "✗ Skills missing or incomplete"
fi
echo ""

# Core Tools
echo "=== Core Tools ==="
gh --version >/dev/null 2>&1 && echo "✓ GitHub CLI installed" || echo "✗ GitHub CLI missing"
gh auth status >/dev/null 2>&1 && echo "✓ GitHub CLI authenticated" || echo "✗ GitHub CLI not authenticated"
jq --version >/dev/null 2>&1 && echo "✓ jq installed" || echo "✗ jq missing"
docker --version >/dev/null 2>&1 && echo "✓ Docker installed" || echo "✗ Docker missing"
echo ""

# Development Environment
echo "=== Development Environment ==="
nvm --version >/dev/null 2>&1 && echo "✓ nvm installed" || echo "✗ nvm missing"
node --version 2>/dev/null && echo "✓ Node.js installed: $(node --version)" || echo "✗ Node.js missing"
command npm --version >/dev/null 2>&1 && echo "✓ npm installed" || echo "✗ npm missing"
tsc --version >/dev/null 2>&1 && echo "✓ TypeScript installed" || echo "✗ TypeScript missing"
if pnpm --version >/dev/null 2>&1; then
    echo "✓ pnpm installed"
elif corepack pnpm --version >/dev/null 2>&1; then
    echo "⊗ pnpm shim missing (run: corepack enable)"
else
    echo "✗ pnpm missing"
fi
sdk version >/dev/null 2>&1 && echo "✓ SDKMAN installed" || echo "✗ SDKMAN missing"
java --version >/dev/null 2>&1 && echo "✓ Java installed" || echo "✗ Java missing"
mvn --version >/dev/null 2>&1 && echo "✓ Maven installed" || echo "✗ Maven missing"
quarkus --version >/dev/null 2>&1 && echo "✓ Quarkus installed" || echo "✗ Quarkus missing"
echo ""

# Optional Tools
echo "=== Optional Tools ==="
helm version >/dev/null 2>&1 && echo "✓ Helm installed" || echo "⊗ Helm not installed (optional)"
kubectl version --client >/dev/null 2>&1 && echo "✓ kubectl installed" || echo "⊗ kubectl not installed (optional)"
minikube version >/dev/null 2>&1 && echo "✓ Minikube installed" || echo "⊗ Minikube not installed (optional)"
echo ""

# Voice Tools
echo "=== Voice Tools ==="
test -d ~/faster-whisper-dictation && echo "✓ faster-whisper cloned" || echo "⊗ faster-whisper not installed (optional)"
test -f ~/.local/bin/dictate-start && echo "✓ Dictation scripts installed" || echo "⊗ Dictation scripts not installed (optional)"
groups | grep -q input && echo "✓ User in input group" || echo "⊗ Not in input group (needed for voice)"
echo ""

echo "========================================="
echo "  Verification Complete"
echo "========================================="
echo ""
echo "Legend:"
echo "  ✓ = Installed and configured"
echo "  ✗ = Missing (required)"
echo "  ⊗ = Not installed (optional)"
echo ""
echo "To fix missing components, see setup-checklist.md"

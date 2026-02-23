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
codex --version 2>/dev/null && echo "✓ Codex installed" || echo "✗ Codex missing"
if [ -L ~/.codex/config.toml ]; then
    echo "✓ ~/.codex/config.toml symlinked"
elif [ -f ~/.codex/config.toml ]; then
    echo "✗ ~/.codex/config.toml exists but is NOT a symlink"
else
    echo "✗ ~/.codex/config.toml missing"
fi
echo ""

# Home Directory Symlinks
echo "=== Home Directory Symlinks ==="
for dotfile in .bashrc .bash_aliases .profile .gitconfig .bash_secrets; do
    if [ -L ~/"$dotfile" ]; then
        echo "✓ ~/$dotfile symlinked"
    elif [ -f ~/"$dotfile" ]; then
        echo "✗ ~/$dotfile exists but is NOT a symlink"
    else
        echo "✗ ~/$dotfile missing"
    fi
done
if [ -L ~/projects/.markdownlint.json ]; then
    echo "✓ ~/projects/.markdownlint.json symlinked"
elif [ -f ~/projects/.markdownlint.json ]; then
    echo "✗ ~/projects/.markdownlint.json exists but is NOT a symlink"
else
    echo "✗ ~/projects/.markdownlint.json missing"
fi
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
skills_source_dir="$(dirname "$0")/configs/agents/skills"
expected_skills=()
for skill_path in "$skills_source_dir"/*/; do
    [ -d "$skill_path" ] || continue
    expected_skills+=("$(basename "$skill_path")")
done
expected_skill_count=${#expected_skills[@]}
claude_skills=$(ls ~/.claude/skills/ 2>/dev/null | wc -l)
cursor_skills=$(ls ~/.cursor/skills/ 2>/dev/null | wc -l)
agent_skills=$(ls ~/.agents/skills/ 2>/dev/null | wc -l)
echo "Expected skills from source: $expected_skill_count directories"
echo "Claude skills: $claude_skills directories"
echo "Cursor skills: $cursor_skills directories"
echo "Agent skills: $agent_skills directories"

skills_missing=0
for target_dir in ~/.claude/skills ~/.cursor/skills ~/.agents/skills; do
    for skill in "${expected_skills[@]}"; do
        if [ ! -e "$target_dir/$skill" ]; then
            echo "✗ Missing skill '$skill' in $target_dir"
            skills_missing=1
        fi
    done
done

if [ "$expected_skill_count" -eq 0 ]; then
    echo "✗ No source skills found in $skills_source_dir"
elif [ "$skills_missing" -eq 0 ]; then
    echo "✓ Skills configured and synced to source"
else
    echo "✗ Skills missing or incomplete vs source"
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
npm --version >/dev/null 2>&1 && echo "✓ npm installed" || echo "✗ npm missing"
tsc --version >/dev/null 2>&1 && echo "✓ TypeScript installed" || echo "✗ TypeScript missing"
if pnpm --version >/dev/null 2>&1; then
    echo "✓ pnpm installed"
elif corepack pnpm --version >/dev/null 2>&1; then
    echo "⊗ pnpm shim missing (run: corepack enable)"
else
    echo "✗ pnpm missing"
fi
if firecrawl --version >/dev/null 2>&1; then
    echo "✓ Firecrawl CLI installed"
    firecrawl_status="$(firecrawl --status 2>/dev/null || true)"
    if echo "$firecrawl_status" | grep -qi "not authenticated"; then
        echo "✗ Firecrawl CLI not authenticated (run: firecrawl login --browser)"
    elif echo "$firecrawl_status" | grep -qi "authenticated"; then
        echo "✓ Firecrawl CLI authenticated"
    else
        echo "✗ Firecrawl auth status unclear (run: firecrawl --status)"
    fi
else
    echo "✗ Firecrawl CLI missing"
fi
if npx --yes playwright --version >/dev/null 2>&1; then
    echo "✓ Playwright installed"
else
    echo "✗ Playwright missing (run: pnpm exec playwright install chromium)"
fi
sdk version >/dev/null 2>&1 && echo "✓ SDKMAN installed" || echo "✗ SDKMAN missing"
if grep -q "sdkman_auto_env=true" ~/.sdkman/etc/config 2>/dev/null; then
    echo "✓ SDKMAN auto-env enabled"
else
    echo "✗ SDKMAN auto-env disabled (set sdkman_auto_env=true in ~/.sdkman/etc/config)"
fi
java --version >/dev/null 2>&1 && echo "✓ Java installed" || echo "✗ Java missing"
mvn --version >/dev/null 2>&1 && echo "✓ Maven installed" || echo "✗ Maven missing"
quarkus --version >/dev/null 2>&1 && echo "✓ Quarkus installed" || echo "✗ Quarkus missing"
if [ -f ~/.redhat/io.quarkus.analytics.localconfig ]; then
    if grep -q '"disabled":false' ~/.redhat/io.quarkus.analytics.localconfig 2>/dev/null; then
        echo "✓ Quarkus build analytics enabled"
    else
        echo "✗ Quarkus build analytics disabled (enable: echo '{\"disabled\":false}' > ~/.redhat/io.quarkus.analytics.localconfig)"
    fi
else
    echo "✗ Quarkus build analytics not configured (will prompt interactively)"
fi
echo ""

# Optional Tools
echo "=== Optional Tools ==="
helm version >/dev/null 2>&1 && echo "✓ Helm installed" || echo "⊗ Helm not installed (optional)"
kubectl version --client >/dev/null 2>&1 && echo "✓ kubectl installed" || echo "⊗ kubectl not installed (optional)"
minikube version >/dev/null 2>&1 && echo "✓ Minikube installed" || echo "⊗ Minikube not installed (optional)"
echo ""

# Voice Tools
echo "=== Voice Tools ==="
voice_detect_script="$(dirname "$0")/scripts/detect-voice-tooling.sh"
wispr_detected=0
if [ -x "$voice_detect_script" ]; then
    voice_output="$("$voice_detect_script")"
    echo "$voice_output"
    if echo "$voice_output" | grep -qi "wispr.*detected\|whisper.*flow.*detected"; then
        wispr_detected=1
    fi
else
    echo "⊗ Voice detector script missing"
fi
if [ "$wispr_detected" -eq 1 ]; then
    echo "✓ Wispr Flow detected — no additional Linux voice tools needed"
else
    test -x ~/.local/bin/dictate-start && echo "✓ dictate-start installed" || echo "⊗ dictate-start missing (optional)"
    command -v nerd-dictation >/dev/null 2>&1 && echo "✓ nerd-dictation installed" || echo "⊗ nerd-dictation missing (optional)"
    command -v talon >/dev/null 2>&1 && echo "✓ Talon installed" || echo "⊗ Talon not detected (optional)"
    groups | grep -q input && echo "✓ User in input group (needed for faster-whisper hotkeys)" || echo "⊗ Not in input group (needed for faster-whisper hotkeys)"
fi
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
echo "To fix missing components, see SETUP.md and setup/*.md"

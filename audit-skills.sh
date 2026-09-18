#!/usr/bin/env bash
# Audit SKILL.md frontmatter in agents/skills/ against the Claude Code frontmatter reference.
# https://code.claude.com/docs/en/skills#frontmatter-reference
#
# Directory-driven: every reachable skill directory under agents/skills/ is checked, no hardcoded
# list. Symlinked skill directories are followed.
# Exits non-zero when any ERROR is found. Use --strict to also fail on WARN.
set -euo pipefail

skills_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agents/skills"

if [ ! -d "$skills_dir" ]; then
    echo "✗ Skills directory not found: $skills_dir" >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "✗ python3 is required for the frontmatter audit" >&2
    exit 1
fi

mapfile -d '' skill_dirs < <(find -L "$skills_dir" -mindepth 1 -maxdepth 1 -type d -print0)

python3 - "$skills_dir" "$@" -- "${skill_dirs[@]}" <<'PYEOF'
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("✗ PyYAML is required: sudo apt install python3-yaml")

skills_dir = Path(sys.argv[1])
separator = sys.argv.index("--")
strict = "--strict" in sys.argv[2:separator]
skill_dirs = [Path(value) for value in sys.argv[separator + 1:]]

# Every field Claude Code accepts (frontmatter reference, 2026-08).
KNOWN = {
    "name", "description", "when_to_use", "argument-hint", "arguments",
    "disable-model-invocation", "user-invocable", "allowed-tools", "disallowed-tools",
    "model", "effort", "context", "agent", "background", "hooks", "paths", "shell",
    "metadata", "license", "compatibility",
}
# The subset the Agent Skills spec allows outside Claude Code (claude.ai, Skills API).
SPEC = {"name", "description", "license", "compatibility", "metadata", "allowed-tools"}

DESC_CAP = 1536       # description + when_to_use are truncated past this in the skill listing
COMPAT_CAP = 500      # compatibility is capped by the spec

errors, warns = [], []
names = {}


def load(skill_md):
    text = skill_md.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return None, "no YAML frontmatter (file does not start with ---)"
    end = text.find("\n---", 3)
    if end == -1:
        return None, "unterminated YAML frontmatter (no closing ---)"
    try:
        data = yaml.safe_load(text[3:end])
    except yaml.YAMLError as exc:
        return None, f"malformed YAML frontmatter: {exc}"
    if data is None:
        return None, "empty YAML frontmatter"
    if not isinstance(data, dict):
        return None, f"frontmatter is {type(data).__name__}, expected a mapping"
    return data, None


for skill_dir in sorted(skill_dirs):
    rel = skill_dir.name
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.is_file():
        errors.append(f"{rel}: no SKILL.md")
        continue

    fm, err = load(skill_md)
    if err:
        errors.append(f"{rel}: {err}")
        continue

    unknown = sorted(set(fm) - KNOWN)
    if unknown:
        errors.append(f"{rel}: unknown frontmatter key(s): {', '.join(unknown)}")

    non_spec = sorted(set(fm) & KNOWN - SPEC)
    if non_spec:
        warns.append(f"{rel}: Claude Code-only key(s), not portable to claude.ai/Skills API: "
                     f"{', '.join(non_spec)}")

    desc = fm.get("description")
    if desc is None:
        errors.append(f"{rel}: no description (Claude cannot match the skill)")
    elif not isinstance(desc, str) or not desc.strip():
        errors.append(f"{rel}: description is empty or not a string")
    else:
        listing = desc + str(fm.get("when_to_use", ""))
        if len(listing) > DESC_CAP:
            warns.append(f"{rel}: description+when_to_use is {len(listing)} chars, "
                         f"truncated at {DESC_CAP} in the skill listing")
        # YAML folded/literal scalars (`>`, `|`) legitimately end in a newline; only flag
        # whitespace that survives once those trailing newlines are removed.
        trimmed = desc.strip("\n")
        if trimmed != trimmed.strip():
            warns.append(f"{rel}: description has leading/trailing whitespace")

    name = fm.get("name")
    if name is not None:
        if not isinstance(name, str):
            errors.append(f"{rel}: name is {type(name).__name__}, expected a string")
        else:
            if name != rel:
                warns.append(f"{rel}: name '{name}' differs from directory name; "
                             f"the listing shows '{name}' but '/{rel}' invokes it")
            names.setdefault(name, []).append(rel)

    meta = fm.get("metadata")
    if meta is not None:
        if not isinstance(meta, dict):
            errors.append(f"{rel}: metadata is {type(meta).__name__}, "
                          f"expected a map (Claude Code drops it)")
        else:
            shadowed = sorted(set(meta) & KNOWN)
            if shadowed:
                errors.append(f"{rel}: metadata reuses frontmatter field name(s) "
                              f"{', '.join(shadowed)}; move them to the top level")

    compat = fm.get("compatibility")
    if isinstance(compat, str) and len(compat) > COMPAT_CAP:
        errors.append(f"{rel}: compatibility is {len(compat)} chars, cap is {COMPAT_CAP}")

for name, dirs in sorted(names.items()):
    if len(dirs) > 1:
        errors.append(f"duplicate name '{name}' declared by: {', '.join(dirs)}")

total = len(skill_dirs)
print(f"=== Skill frontmatter audit ({total} skills in {skills_dir}) ===")
for e in errors:
    print(f"✗ ERROR {e}")
for w in warns:
    print(f"! WARN  {w}")
if not errors and not warns:
    print("✓ All skill frontmatter valid")
else:
    print(f"\n{len(errors)} error(s), {len(warns)} warning(s)")

sys.exit(1 if errors or (strict and warns) else 0)
PYEOF

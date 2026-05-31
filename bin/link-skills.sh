#!/usr/bin/env bash
# Link every skill in this harness into a Claude Code skills directory.
#
# Claude Code discovers a skill by finding a folder that contains a SKILL.md
# DIRECTLY inside a skills dir (~/.claude/skills for personal, .claude/skills
# in a repo for project scope). Our repo nests skills under skills/local/ and
# skills/vendor/<source>/, so this script flattens them via symlink.
#
# Usage:
#   bin/link-skills.sh                 # link into ./.claude/skills (project scope, cwd)
#   bin/link-skills.sh ~/myrepo        # link into ~/myrepo/.claude/skills (project scope)
#   bin/link-skills.sh --user          # link into ~/.claude/skills (personal scope)
#
# Re-run anytime; existing links are refreshed. Name collisions are reported, not overwritten.

set -euo pipefail

HARNESS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_SRC="$HARNESS_ROOT/skills"

if [[ "${1:-}" == "--user" ]]; then
  TARGET="$HOME/.claude/skills"
else
  TARGET="${1:-$PWD}/.claude/skills"
fi

mkdir -p "$TARGET"
echo "Linking skills from: $SKILLS_SRC"
echo "Into:                $TARGET"
echo

linked=0
skipped=0

# Any directory containing a SKILL.md is a skill. Link it by its own basename.
while IFS= read -r -d '' skillmd; do
  skill_dir="$(dirname "$skillmd")"
  name="$(basename "$skill_dir")"
  dest="$TARGET/$name"

  if [[ -L "$dest" ]]; then
    # refresh an existing symlink
    rm "$dest"
  elif [[ -e "$dest" ]]; then
    echo "  ! SKIP $name — a real file/dir already exists at $dest (resolve by hand)"
    skipped=$((skipped + 1))
    continue
  fi

  ln -s "$skill_dir" "$dest"
  echo "  + $name -> $skill_dir"
  linked=$((linked + 1))
done < <(find "$SKILLS_SRC" -name SKILL.md -print0 | sort -z)

echo
echo "Linked $linked skill(s), skipped $skipped."
echo
echo "Note: this links ONLY the local + vendored skills in this harness."
echo "superpowers is installed separately as a plugin (see README). Start a new"
echo "Claude Code session in the target repo for the skills to load."

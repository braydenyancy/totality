#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/braydenyancy/totality.git"
INSTALL_DIR="${TOTALITY_DIR:-$HOME/.local/share/totality}"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
TAG="totality:managed"

usage() {
  cat <<EOF
Totality installer

Usage:
  install.sh              Install (clones to \$TOTALITY_DIR if needed)
  install.sh --update     git pull and relink
  install.sh --uninstall  Remove symlinks and managed hook entries
  install.sh --help       Show this

Environment:
  TOTALITY_DIR  Override install location (default: ~/.local/share/totality)
  CLAUDE_HOME   Override Claude config dir   (default: ~/.claude)
EOF
}

require() {
  command -v "$1" >/dev/null 2>&1 || { echo "error: $1 is required but not installed" >&2; exit 1; }
}

resolve_source() {
  # If this script lives inside a checkout (sibling skills/ + .claude-plugin/), use it.
  local script_path="${BASH_SOURCE[0]:-$0}"
  local script_dir=""
  if [ -f "$script_path" ]; then
    script_dir="$(cd "$(dirname "$script_path")" && pwd)"
  fi
  if [ -n "$script_dir" ] && [ -d "$script_dir/skills" ] && [ -d "$script_dir/.claude-plugin" ]; then
    SOURCE_DIR="$script_dir"
    return
  fi

  # Otherwise clone or update INSTALL_DIR.
  require git
  if [ -d "$INSTALL_DIR/.git" ]; then
    echo "→ updating $INSTALL_DIR"
    git -C "$INSTALL_DIR" pull --ff-only
  else
    echo "→ cloning into $INSTALL_DIR"
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
  fi
  SOURCE_DIR="$INSTALL_DIR"
}

link_dir() {
  local kind="$1"
  local src="$SOURCE_DIR/$kind"
  local dst="$CLAUDE_DIR/$kind"
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  for entry in "$src"/*; do
    [ -e "$entry" ] || continue
    local name target
    name="$(basename "$entry")"
    target="$dst/$name"
    if [ -L "$target" ]; then
      rm "$target"
    elif [ -e "$target" ]; then
      echo "  ! $target exists and is not a symlink — skipping"
      continue
    fi
    ln -s "$entry" "$target"
    echo "  ✓ $kind/$name"
  done
}

unlink_dir() {
  local kind="$1"
  local src="$SOURCE_DIR/$kind"
  local dst="$CLAUDE_DIR/$kind"
  [ -d "$src" ] || return 0
  for entry in "$src"/*; do
    [ -e "$entry" ] || continue
    local name target
    name="$(basename "$entry")"
    target="$dst/$name"
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$entry" ]; then
      rm "$target"
      echo "  ✓ removed $kind/$name"
    fi
  done
}

merge_hooks() {
  local hooks_file="$SOURCE_DIR/hooks/hooks.json"
  [ -f "$hooks_file" ] || return 0
  require node
  mkdir -p "$CLAUDE_DIR"
  [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
  TAG="$TAG" node - "$SETTINGS" "$hooks_file" <<'JS'
const fs = require('fs');
const TAG = process.env.TAG;
const [, , settingsPath, hooksPath] = process.argv;
const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
const incoming = JSON.parse(fs.readFileSync(hooksPath, 'utf8'));
settings.hooks = settings.hooks || {};
for (const [event, entries] of Object.entries(incoming.hooks || {})) {
  settings.hooks[event] = (settings.hooks[event] || []).filter(e =>
    !(e.hooks || []).some(h => h._managedBy === TAG)
  );
  for (const entry of entries) {
    settings.hooks[event].push({
      ...entry,
      hooks: (entry.hooks || []).map(h => ({ ...h, _managedBy: TAG })),
    });
  }
}
fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
console.log('  ✓ hooks merged into', settingsPath);
JS
}

check_external_deps() {
  # Probe external skills (not Claude Code plugins, but required by some flows).
  # Source of truth: skills/doctor/plugin-matrix.md → "External skills" table.
  local da_path="$CLAUDE_DIR/skills/devils-advocate/SKILL.md"
  if [ ! -f "$da_path" ]; then
    echo
    echo "⚠ external dependency not installed: devils-advocate"
    echo "  rnd will halt without it (mandatory pre-Phase-4 challenge)."
    echo "  install with:"
    echo "    npx degit notmanas/claude-code-skills/skills/devils-advocate $CLAUDE_DIR/skills/devils-advocate"
  else
    echo "  ✓ external skill devils-advocate present"
  fi
}

remove_hooks() {
  [ -f "$SETTINGS" ] || return 0
  require node
  TAG="$TAG" node - "$SETTINGS" <<'JS'
const fs = require('fs');
const TAG = process.env.TAG;
const [, , settingsPath] = process.argv;
const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
let changed = false;
for (const event of Object.keys(settings.hooks || {})) {
  const before = settings.hooks[event].length;
  settings.hooks[event] = settings.hooks[event].filter(e =>
    !(e.hooks || []).some(h => h._managedBy === TAG)
  );
  if (settings.hooks[event].length !== before) changed = true;
  if (settings.hooks[event].length === 0) delete settings.hooks[event];
}
if (settings.hooks && Object.keys(settings.hooks).length === 0) delete settings.hooks;
fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
console.log(changed ? '  ✓ hooks removed' : '  · no totality hooks found');
JS
}

main() {
  case "${1:-install}" in
    -h|--help)
      usage
      ;;
    --update)
      resolve_source
      echo "→ relinking from $SOURCE_DIR"
      link_dir skills
      link_dir agents
      link_dir commands
      merge_hooks
      echo "→ checking external deps"
      check_external_deps
      echo "✓ updated — restart Claude Code to pick up changes"
      ;;
    --uninstall)
      resolve_source
      echo "→ removing symlinks"
      unlink_dir skills
      unlink_dir agents
      unlink_dir commands
      echo "→ removing hooks"
      remove_hooks
      echo "✓ uninstalled"
      echo "  source repo at $SOURCE_DIR left intact (rm -rf if you want it gone)"
      ;;
    install|"")
      resolve_source
      echo "→ linking skills"
      link_dir skills
      echo "→ linking agents"
      link_dir agents
      echo "→ linking commands"
      link_dir commands
      echo "→ merging hooks"
      merge_hooks
      echo "→ checking external deps"
      check_external_deps
      echo
      echo "✓ totality installed"
      echo "  source: $SOURCE_DIR"
      echo "  restart Claude Code to pick up changes"
      ;;
    *)
      echo "unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"

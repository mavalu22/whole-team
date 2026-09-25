#!/usr/bin/env bash
# WholeTeam installer for Linux, macOS and Git Bash on Windows.
# Copies the factory into an existing git project, or updates an installed one.
# Requires only bash 3.2+ and git. See README.md, section "Install".

set -eu
set -o pipefail

BLOCK_BEGIN_MD='<!-- >>> whole-team >>> -->'
BLOCK_END_MD='<!-- <<< whole-team <<< -->'
BLOCK_BEGIN_IGNORE='# >>> whole-team >>>'
BLOCK_END_IGNORE='# <<< whole-team <<<'

ARG_PATH=""
ARG_TYPE=""
ARG_MODE=""
ASSUME_YES=0
TMP_FILES=""
OLD_MANIFEST=""
ROOT_MODE="install"

usage() {
  cat <<'EOF'
Usage: ./install.sh [--path <project>] [--type new|ongoing] [--mode install|update] [--yes] [--help]

Installs WholeTeam into an existing git project, or updates an installed one.

Options:
  --path <project>   Project folder (must already be a git repository).
  --type <type>      new     = a new product; Discovery starts from the idea.
                     ongoing = an existing codebase; Discovery starts by analysing the code.
  --mode <mode>      install or update. Detected automatically when omitted.
  --yes              Accept defaults and never prompt. Fails if the path is missing.
  --help             Show this help.

Any missing value is asked interactively.
EOF
}

info() { printf '%s\n' "$*"; }
warn() { printf 'Warning: %s\n' "$*" >&2; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

cleanup() {
  if [ -n "$TMP_FILES" ]; then
    # shellcheck disable=SC2086
    rm -f $TMP_FILES
  fi
}
trap cleanup EXIT

make_temp() {
  local t
  t=$(mktemp "${TMPDIR:-/tmp}/wholeteam.XXXXXX") || die "Cannot create a temporary file."
  TMP_FILES="$TMP_FILES $t"
  printf '%s' "$t"
}

# ask <prompt> <default> -> prints the answer (the default when empty or --yes)
ask() {
  local prompt="$1" default="$2" answer=""
  if [ "$ASSUME_YES" -eq 1 ]; then
    printf '%s' "$default"
    return 0
  fi
  printf '%s ' "$prompt" >&2
  IFS= read -r answer || answer=""
  if [ -z "$answer" ]; then
    answer="$default"
  fi
  printf '%s' "$answer"
}

# confirm <prompt> -> 0 for yes (default), 1 for no
confirm() {
  local answer
  answer=$(ask "$1 [Y/n]" "y")
  case "$answer" in
    [Nn]|[Nn][Oo]) return 1 ;;
    *) return 0 ;;
  esac
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# normalize_path <raw> -> absolute path of an existing folder, or empty
normalize_path() {
  local p
  p=$(trim "$1")
  case "$p" in
    \"*\") p="${p#\"}"; p="${p%\"}" ;;
    \'*\') p="${p#\'}"; p="${p%\'}" ;;
  esac
  case "$p" in
    \~) p="$HOME" ;;
    \~/*) p="$HOME/${p#\~/}" ;;
  esac
  case "$p" in
    [A-Za-z]:\\*|[A-Za-z]:/*)
      if command -v cygpath >/dev/null 2>&1; then
        p=$(cygpath -u "$p")
      fi
      ;;
  esac
  if [ -n "$p" ] && [ -d "$p" ]; then
    (cd "$p" && pwd -P)
  else
    printf '%s' "$p"
  fi
}

is_tracked() {
  git -C "$PROJECT" ls-files --error-unmatch -- "$1" >/dev/null 2>&1
}

# write_content <source> <target>: replace content while keeping the target's permissions
write_content() {
  cat "$1" > "$2"
}

# block_lines <file> <begin marker> <end marker> -> "<begin line> <end line> <any end>"
# Lines are 0 when absent; the end line is the first end marker after the begin marker.
# Marker lines are compared with a trailing carriage return removed.
block_lines() {
  awk -v b="$2" -v e="$3" '
    { l = $0; sub(/\r$/, "", l) }
    l == e { any = 1; if (bl && !el) el = NR }
    l == b && !bl { bl = NR }
    END { printf "%d %d %d\n", bl, el, any }' "$1"
}

# check_block <file> <begin marker> <end marker>: stops when the file has an incomplete block
check_block() {
  local file="$1" begin_line end_line any_end
  [ -f "$file" ] || return 0
  read -r begin_line end_line any_end <<EOF
$(block_lines "$file" "$2" "$3")
EOF
  if [ "$begin_line" -gt 0 ] && [ "$end_line" -gt 0 ]; then
    return 0
  fi
  if [ "$begin_line" -eq 0 ] && [ "$any_end" -eq 0 ]; then
    return 0
  fi
  die "$file has an incomplete WholeTeam block (one marker is missing). Fix or remove the markers, then run the installer again."
}

# update_block <file> <block file> <begin marker> <end marker>
# Replaces the text between the markers, or appends the block after a blank line.
update_block() {
  local file="$1" block="$2" begin="$3" end="$4" tmp begin_line end_line any_end
  if [ ! -f "$file" ]; then
    cat "$block" > "$file"
    return 0
  fi
  check_block "$file" "$begin" "$end"
  read -r begin_line end_line any_end <<EOF
$(block_lines "$file" "$begin" "$end")
EOF
  tmp=$(make_temp)
  if [ "$begin_line" -gt 0 ]; then
    awk -v b="$begin_line" -v e="$end_line" -v bf="$block" '
      BEGIN { while ((getline line < bf) > 0) blk = blk line "\n" }
      NR == b { printf "%s", blk }
      NR >= b && NR <= e { next }
      { print }' "$file" > "$tmp"
  else
    cat "$file" > "$tmp"
    if [ -s "$file" ]; then
      if [ "$(tail -c 1 "$file" | od -An -c | tr -d ' ')" != '\n' ]; then
        printf '\n' >> "$tmp"
      fi
      printf '\n' >> "$tmp"
    fi
    cat "$block" >> "$tmp"
  fi
  write_content "$tmp" "$file"
}

# manifest_status <file> -> "created", "block" or "" from the previous manifest
manifest_status() {
  if [ -n "$OLD_MANIFEST" ] && [ -f "$OLD_MANIFEST" ]; then
    awk -v f="$1" '$2 == f { print $1; exit }' "$OLD_MANIFEST"
  fi
}

manifest_has() {
  [ -n "$OLD_MANIFEST" ] && [ -f "$OLD_MANIFEST" ] && awk -v f="$1" '$2 == f { found = 1 } END { exit !found }' "$OLD_MANIFEST"
}

# record <action> <file>: add a line to the new manifest, keeping "created" from the old one
record() {
  local action="$1" file="$2" previous
  previous=$(manifest_status "$file")
  if [ "$previous" = "created" ]; then
    action="created"
  fi
  printf '%s %s\n' "$action" "$file" >> "$NEW_MANIFEST"
}

die_both_tracked() {
  die "$1 and $2 are both tracked by git. Untrack $2 (git rm --cached $2), or paste the block from $3 into it by hand, then run the installer again."
}

# apply_guide <main file> <fallback file> <block template>: section 4.3 rules
apply_guide() {
  local main="$1" fallback="$2" block="$3"
  if [ ! -e "$PROJECT/$main" ]; then
    update_block "$PROJECT/$main" "$block" "$BLOCK_BEGIN_MD" "$BLOCK_END_MD"
    record created "$main"
  elif ! is_tracked "$main"; then
    update_block "$PROJECT/$main" "$block" "$BLOCK_BEGIN_MD" "$BLOCK_END_MD"
    record block "$main"
  else
    if is_tracked "$fallback"; then
      die_both_tracked "$main" "$fallback" "$block"
    fi
    if [ -e "$PROJECT/$fallback" ]; then
      update_block "$PROJECT/$fallback" "$block" "$BLOCK_BEGIN_MD" "$BLOCK_END_MD"
      record block "$fallback"
    else
      update_block "$PROJECT/$fallback" "$block" "$BLOCK_BEGIN_MD" "$BLOCK_END_MD"
      record created "$fallback"
    fi
    info "  $main is tracked by git: left untouched; the WholeTeam block is in $fallback."
  fi
}

# write_ignore_block <target file>: section 4.4 block, listing only files the factory created
write_ignore_block() {
  local target="$1" block f
  block=$(make_temp)
  {
    printf '%s\n' "$BLOCK_BEGIN_IGNORE"
    printf '%s\n' "/factory/"
    printf '%s\n' "/.claude/agents/factory-*.md"
    printf '%s\n' "/.codex/agents/factory-*.toml"
    for f in CLAUDE.md AGENTS.md CLAUDE.local.md AGENTS.override.md; do
      if awk -v f="$f" '$1 == "created" && $2 == f { found = 1 } END { exit !found }' "$NEW_MANIFEST"; then
        printf '/%s\n' "$f"
      fi
    done
    printf '%s\n' "$BLOCK_END_IGNORE"
  } > "$block"
  update_block "$target" "$block" "$BLOCK_BEGIN_IGNORE" "$BLOCK_END_IGNORE"
}

# ignore_target -> where the ignore block lives: .gitignore, or the file the old manifest names
ignore_target() {
  local line=""
  if [ -n "$OLD_MANIFEST" ] && [ -f "$OLD_MANIFEST" ]; then
    line=$(awk '$2 != "CLAUDE.md" && $2 != "AGENTS.md" && $2 != "CLAUDE.local.md" && $2 != "AGENTS.override.md" { print $2; exit }' "$OLD_MANIFEST")
  fi
  printf '%s' "${line:-.gitignore}"
}

# ignore_path <target> -> absolute path of the ignore target
ignore_path() {
  case "$1" in
    /*) printf '%s' "$1" ;;
    [A-Za-z]:*) normalize_path "$1" ;;
    *) printf '%s' "$PROJECT/$1" ;;
  esac
}

# apply_ignore: refresh the ignore block where the old manifest says it lives
apply_ignore() {
  local target abs
  target=$(ignore_target)
  abs=$(ignore_path "$target")
  if [ ! -e "$abs" ]; then
    mkdir -p "$(dirname "$abs")"
    write_ignore_block "$abs"
    record created "$target"
  else
    write_ignore_block "$abs"
    record block "$target"
  fi
}

set_config_type() {
  local file="$PROJECT/factory/config.yaml" tmp
  tmp=$(make_temp)
  awk -v t="$1" '
    /^project:/ { inp = 1; print; next }
    inp && /^[^ #]/ { inp = 0 }
    inp && !done && /^  type:/ { print "  type: " t; done = 1; next }
    { print }' "$file" > "$tmp"
  grep -q "^  type: $1\$" "$tmp" || die "Could not set project.type in $file."
  write_content "$tmp" "$file"
}

set_state_version() {
  local file="$PROJECT/factory/state.yaml" tmp
  tmp=$(make_temp)
  awk -v v="$VERSION" '
    /^factory_version:/ && !done { print "factory_version: \"" v "\""; done = 1; next }
    { print }' "$file" > "$tmp"
  write_content "$tmp" "$file"
}

copy_agents() {
  local f
  mkdir -p "$PROJECT/.claude/agents" "$PROJECT/.codex/agents"
  for f in "$PROJECT"/.claude/agents/factory-*.md "$PROJECT"/.codex/agents/factory-*.toml; do
    if [ -f "$f" ]; then
      rm -f "$f"
    fi
  done
  cp "$TEMPLATE"/root/.claude/agents/factory-*.md "$PROJECT/.claude/agents/"
  cp "$TEMPLATE"/root/.codex/agents/factory-*.toml "$PROJECT/.codex/agents/"
  printf '%s\n%s\n' \
    'The WholeTeam installer rewrote the agent files with default models.' \
    'On the next `Let'"'"'s code`, the Orchestrator re-applies the models block of factory/config.yaml and deletes this file.' \
    > "$PROJECT/factory/.models-sync-needed"
}

write_core_version() {
  printf '%s\n' "$VERSION" > "$PROJECT/factory/core/VERSION"
}

apply_root_files() {
  NEW_MANIFEST=$(make_temp)
  : > "$NEW_MANIFEST"
  if [ "$1" = "install" ] || manifest_has "CLAUDE.md" || manifest_has "CLAUDE.local.md"; then
    apply_guide "CLAUDE.md" "CLAUDE.local.md" "$TEMPLATE/root/CLAUDE.md"
  fi
  if [ "$1" = "install" ] || manifest_has "AGENTS.md" || manifest_has "AGENTS.override.md"; then
    apply_guide "AGENTS.md" "AGENTS.override.md" "$TEMPLATE/root/AGENTS.md"
  fi
  apply_ignore
  cat "$NEW_MANIFEST" > "$PROJECT/factory/.install-manifest"
}

# load_old_manifest <mode>: sets OLD_MANIFEST and ROOT_MODE for the root files.
# ROOT_MODE is "update" only when an update finds a non-empty manifest.
load_old_manifest() {
  OLD_MANIFEST=""
  ROOT_MODE="install"
  if [ "$1" = "update" ]; then
    OLD_MANIFEST=$(make_temp)
    if [ -f "$PROJECT/factory/.install-manifest" ]; then
      cat "$PROJECT/factory/.install-manifest" > "$OLD_MANIFEST"
    else
      warn "factory/.install-manifest is missing; the root files are handled as in a new install."
      : > "$OLD_MANIFEST"
    fi
    if [ -s "$OLD_MANIFEST" ]; then
      ROOT_MODE="update"
    fi
  fi
}

# preflight_root_files: takes the decisions apply_root_files will take, without writing,
# and stops before the first write when one of them would fail.
preflight_root_files() {
  local pair main fallback target
  for pair in "CLAUDE.md CLAUDE.local.md" "AGENTS.md AGENTS.override.md"; do
    main="${pair% *}"
    fallback="${pair#* }"
    if [ "$ROOT_MODE" = "update" ] && ! manifest_has "$main" && ! manifest_has "$fallback"; then
      continue
    fi
    target="$main"
    if [ -e "$PROJECT/$main" ] && is_tracked "$main"; then
      if is_tracked "$fallback"; then
        die_both_tracked "$main" "$fallback" "$TEMPLATE/root/$main"
      fi
      target="$fallback"
    fi
    check_block "$PROJECT/$target" "$BLOCK_BEGIN_MD" "$BLOCK_END_MD"
  done
  check_block "$(ignore_path "$(ignore_target)")" "$BLOCK_BEGIN_IGNORE" "$BLOCK_END_IGNORE"
}

print_root_summary() {
  local action file
  info "Root files:"
  while read -r action file; do
    [ -n "$file" ] || continue
    if [ "$action" = "created" ]; then
      info "  created    $file"
    else
      info "  block in   $file"
    fi
  done < "$PROJECT/factory/.install-manifest"
}

do_install() {
  local type="$ARG_TYPE" choice
  if [ -z "$type" ]; then
    if [ "$ASSUME_YES" -eq 1 ]; then
      type="new"
    else
      info ""
      info "Project type:"
      info "  1) new      A new product; Discovery starts from the idea."
      info "  2) ongoing  An existing codebase; Discovery starts by analysing the code."
      while [ -z "$type" ]; do
        choice=$(ask "Choose 1 or 2 [1]:" "1")
        case "$choice" in
          1|new) type="new" ;;
          2|ongoing) type="ongoing" ;;
          *) warn "Please answer 1 (new) or 2 (ongoing)." ;;
        esac
      done
    fi
  fi

  info ""
  info "Installing WholeTeam $VERSION into $PROJECT (type: $type) ..."
  cp -R "$TEMPLATE/factory" "$PROJECT/factory"
  write_core_version
  set_config_type "$type"
  set_state_version
  copy_agents
  apply_root_files install

  info ""
  info "WholeTeam $VERSION is installed."
  print_root_summary
  info ""
  info "Next steps:"
  info "  1. Open the project in VS Code:  code \"$PROJECT\""
  info "  2. Start Claude Code (claude) or Codex (codex) in the project root."
  info "     Recommended main-session model: Claude Code 'sonnet'; Codex 'gpt-6-sol' at medium effort."
  info "  3. Type: Let's code"
  info ""
  info "Factory files live in factory/, which git ignores. Back that folder up."
}

do_update() {
  local installed rel src dest copied=0 before after
  installed=$(tr -d ' \r\n' < "$PROJECT/factory/core/VERSION")
  info ""
  info "Updating WholeTeam $installed -> $VERSION in $PROJECT ..."

  rm -rf "$PROJECT/factory/core"
  cp -R "$TEMPLATE/factory/core" "$PROJECT/factory/core"
  write_core_version
  copy_agents

  before=""
  if is_tracked ".gitignore"; then
    before=$(git -C "$PROJECT" diff --quiet -- .gitignore && printf 'clean' || printf 'dirty')
  fi
  apply_root_files "$ROOT_MODE"
  if [ "$before" = "clean" ]; then
    after=$(git -C "$PROJECT" diff --quiet -- .gitignore && printf 'clean' || printf 'dirty')
    if [ "$after" = "dirty" ]; then
      info "  The WholeTeam block in .gitignore changed. Commit it:"
      info "    git add .gitignore && git commit -m \"chore: update WholeTeam ignore rules\""
    fi
  fi

  while IFS= read -r rel; do
    rel="${rel#./}"
    src="$TEMPLATE/factory/$rel"
    dest="$PROJECT/factory/$rel"
    if [ ! -e "$dest" ]; then
      mkdir -p "$(dirname "$dest")"
      cp "$src" "$dest"
      copied=$((copied + 1))
      info "  added missing starting file factory/$rel"
    fi
  done <<EOF
$(cd "$TEMPLATE/factory" && find . -type f ! -path './core/*' | sort)
EOF

  info ""
  info "WholeTeam is updated to $VERSION."
  print_root_summary
  if [ "$copied" -eq 0 ]; then
    info "No starting files were missing. Your config, state, tasks, bugs, input and output were not touched."
  fi
  info ""
  info "On your next \`Let's code\`, the Orchestrator will migrate your config and state to the new version if needed."
  info "The update reset the agent files to the default models; the next \`Let's code\` re-applies the models from factory/config.yaml."
}

main() {
  local raw top mode proposed installed

  while [ $# -gt 0 ]; do
    case "$1" in
      --path) [ $# -ge 2 ] || die "--path needs a value."; ARG_PATH="$2"; shift 2 ;;
      --path=*) ARG_PATH="${1#*=}"; shift ;;
      --type) [ $# -ge 2 ] || die "--type needs a value."; ARG_TYPE="$2"; shift 2 ;;
      --type=*) ARG_TYPE="${1#*=}"; shift ;;
      --mode) [ $# -ge 2 ] || die "--mode needs a value."; ARG_MODE="$2"; shift 2 ;;
      --mode=*) ARG_MODE="${1#*=}"; shift ;;
      --yes|-y) ASSUME_YES=1; shift ;;
      --help|-h) usage; exit 0 ;;
      *) die "Unknown option: $1 (see --help)" ;;
    esac
  done
  case "$ARG_TYPE" in ""|new|ongoing) ;; *) die "--type must be new or ongoing." ;; esac
  case "$ARG_MODE" in ""|install|update) ;; *) die "--mode must be install or update." ;; esac

  command -v git >/dev/null 2>&1 || die "git was not found on PATH. Install git, then run the installer again."
  SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
  TEMPLATE="$SCRIPT_DIR/template"
  if [ ! -f "$SCRIPT_DIR/VERSION" ] || [ ! -d "$TEMPLATE/factory/core" ]; then
    die "Run this script from a complete WholeTeam folder (VERSION or template/ is missing next to it)."
  fi
  VERSION=$(tr -d ' \r\n' < "$SCRIPT_DIR/VERSION")

  info "WholeTeam installer $VERSION"

  raw="$ARG_PATH"
  if [ -z "$raw" ]; then
    [ "$ASSUME_YES" -eq 0 ] || die "--yes needs --path <project>."
    raw=$(ask "Path to your project folder (paste it here):" "")
    [ -n "$raw" ] || die "No path given."
  fi
  PROJECT=$(normalize_path "$raw")
  [ -d "$PROJECT" ] || die "Folder not found: $PROJECT. The factory never creates project folders: create or clone your project first, then run the installer again."

  if ! git -C "$PROJECT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    die "This folder is not a git repository. Create or clone your project first, then run the installer again."
  fi
  top=$(git -C "$PROJECT" rev-parse --show-toplevel)
  top=$(normalize_path "$top")
  if [ "$top" != "$PROJECT" ]; then
    info "This folder is inside the git repository at: $top"
    if confirm "WholeTeam installs at the repository top level. Use $top?"; then
      PROJECT="$top"
    else
      die "Installation cancelled. Run the installer with the repository's top-level folder."
    fi
  fi
  if [ "$PROJECT" = "$SCRIPT_DIR" ] || { [ -f "$PROJECT/install.sh" ] && [ -f "$PROJECT/template/factory/core/FACTORY.md" ]; }; then
    die "This is the WholeTeam folder itself. Give the path of your project instead."
  fi

  if [ -f "$PROJECT/factory/core/VERSION" ]; then
    installed=$(tr -d ' \r\n' < "$PROJECT/factory/core/VERSION")
    proposed="update"
    info "WholeTeam $installed is installed in this project; the new version is $VERSION."
  elif [ -e "$PROJECT/factory" ]; then
    die "$PROJECT/factory exists but is not a WholeTeam installation (factory/core/VERSION is missing). Rename or move that folder, then run the installer again."
  else
    proposed="install"
  fi

  mode="$ARG_MODE"
  if [ -z "$mode" ]; then
    if [ "$proposed" = "update" ]; then
      confirm "Update WholeTeam $installed -> $VERSION?" || { info "Nothing changed."; exit 0; }
    else
      confirm "Install WholeTeam $VERSION into $PROJECT?" || { info "Nothing changed."; exit 0; }
    fi
    mode="$proposed"
  elif [ "$mode" = "install" ] && [ "$proposed" = "update" ]; then
    info "WholeTeam is already installed here: running update instead, so your factory files are kept."
    mode="update"
  elif [ "$mode" = "update" ] && [ "$proposed" = "install" ]; then
    die "WholeTeam is not installed in $PROJECT. Run the installer with --mode install."
  fi

  load_old_manifest "$mode"
  preflight_root_files

  if [ "$mode" = "install" ]; then
    do_install
  else
    do_update
  fi
}

main ${1+"$@"}

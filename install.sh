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
UPDATE_DIR=""
UPDATE_COUNT=0
STAGED_TARGET=""

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
  local status=$?
  trap - EXIT
  if [ -n "$UPDATE_DIR" ]; then
    if ! recover_update; then
      warn "Recovery is incomplete. Keep $UPDATE_DIR and run the installer again to retry it."
      status=1
    fi
  fi
  if [ -n "$TMP_FILES" ]; then
    # shellcheck disable=SC2086
    rm -f $TMP_FILES
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

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

# Each journal entry contains a target, a staged replacement (when needed), and
# the original moved to "old" during promotion. No installed file changes until
# every replacement is staged and validated and the "ready" marker is written.
stage_target() {
  local target="$1" entry relative
  UPDATE_COUNT=$((UPDATE_COUNT + 1))
  entry="$UPDATE_DIR/entries/$(printf '%06d' "$UPDATE_COUNT")"
  mkdir -p "$entry"
  relative="$target"
  case "$target" in "$PROJECT"/*) relative="${target#"$PROJECT"/}" ;; esac
  printf '%s\n' "$relative" > "$entry/target"
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    : > "$entry/absent"
  fi
  STAGED_TARGET="$entry/new"
}

validate_copy() {
  git diff --no-index --quiet --no-ext-diff --no-textconv -- "$1" "$2" ||
    die "Staged copy validation failed for $1. The installed version has not changed."
}

stage_file() {
  stage_target "$1"
  if [ -e "$1" ] || [ -L "$1" ]; then
    [ -f "$1" ] || die "Expected a file at $1."
    cp -p "$1" "$STAGED_TARGET"
    validate_copy "$1" "$STAGED_TARGET"
  fi
}

# Recovery is retryable even if interrupted while restoring an original: an
# entry whose "old" has already been moved back must be left alone on retry.
recover_update() {
  local dir="$PROJECT/factory/.wholeteam-update" entry target owner_runtime owner_pid runtime
  [ -e "$dir" ] || return 0
  if [ ! -f "$dir/format" ] || [ "$(cat "$dir/format")" != 'wholeteam-update-v1' ]; then
    warn "Unrecognized update directory: $dir. Keep its contents and move it aside before retrying."
    return 1
  fi
  if [ -z "$UPDATE_DIR" ]; then
    [ -f "$dir/owner" ] || { warn "Update owner is missing in $dir; keep the journal for recovery."; return 1; }
    read -r owner_runtime owner_pid < "$dir/owner" || return 1
    case "$owner_pid" in ''|*[!0-9]*) warn "Invalid update owner in $dir."; return 1 ;; esac
    runtime=unix
    case "$OSTYPE" in msys*|cygwin*) runtime=bash ;; esac
    if [ "$owner_runtime" != "$runtime" ]; then
      warn "Use the $owner_runtime installer to recover $dir safely."
      return 1
    fi
    if kill -0 "$owner_pid" 2>/dev/null; then
      warn "Another WholeTeam update is still running (process $owner_pid)."
      return 1
    fi
  fi
  if [ -f "$dir/ready" ] && [ ! -f "$dir/committed" ]; then
    info "Recovering an unfinished WholeTeam update ..."
    for entry in "$dir"/entries/*; do
      [ -d "$entry" ] || continue
      [ -f "$entry/target" ] || return 1
      IFS= read -r target < "$entry/target" || return 1
      target=$(ignore_path "$target") || return 1
      if [ -e "$entry/old" ] || [ -L "$entry/old" ]; then
        rm -rf "$target" || return 1
        mv "$entry/old" "$target" || return 1
      elif [ -f "$entry/absent" ] && [ ! -e "$entry/new" ]; then
        rm -rf "$target" || return 1
      fi
    done
    info "The previous WholeTeam version was restored."
  fi
  # Remove "ready" before deleting backups, so interrupted cleanup can never
  # be mistaken for an unfinished promotion.
  rm -f "$dir/ready" || return 1
  rm -rf "$dir" || return 1
  UPDATE_DIR=""
}

promote_update() {
  local entry target
  : > "$UPDATE_DIR/ready.tmp"
  mv "$UPDATE_DIR/ready.tmp" "$UPDATE_DIR/ready"
  for entry in "$UPDATE_DIR"/entries/*; do
    IFS= read -r target < "$entry/target"
    target=$(ignore_path "$target")
    mkdir -p "$(dirname "$target")"
    if [ -f "$entry/absent" ]; then
      [ ! -e "$target" ] && [ ! -L "$target" ] || die "Update target appeared during staging: $target."
    else
      [ -e "$target" ] || [ -L "$target" ] || die "Update target disappeared during staging: $target."
      mv "$target" "$entry/old"
    fi
    if [ -e "$entry/new" ]; then
      mv "$entry/new" "$target"
    fi
  done
  : > "$UPDATE_DIR/committed.tmp"
  mv "$UPDATE_DIR/committed.tmp" "$UPDATE_DIR/committed"
  recover_update
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
  if [ -n "$UPDATE_DIR" ]; then
    stage_file "$file"
    file="$STAGED_TARGET"
  fi
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

# parse_manifest <manifest>: normalize action/path records without splitting paths.
# Only the first space or tab separates the action from the complete path.
parse_manifest() {
  awk '
    {
      line = $0
      sub(/\r$/, "", line)
      sub(/^[ \t]+/, "", line)
      if (!match(line, /^[^ \t]+[ \t]/)) next
      action = substr(line, 1, RLENGTH - 1)
      path = substr(line, RLENGTH + 1)
      if (path != "") printf "%s %s\n", action, path
    }' "$1"
}

# manifest_status <file> [manifest] -> "created", "block" or "" (old by default)
manifest_status() {
  local manifest="${2:-$OLD_MANIFEST}"
  if [ -n "$manifest" ] && [ -f "$manifest" ]; then
    # ENVIRON keeps literal backslashes in paths; awk -v interprets escapes.
    parse_manifest "$manifest" | WHOLETEAM_MANIFEST_PATH="$1" awk '
      !found && substr($0, index($0, " ") + 1) == ENVIRON["WHOLETEAM_MANIFEST_PATH"] {
        action = $1; found = 1
      }
      END { if (found) print action }'
  fi
}

manifest_has() {
  [ -n "$(manifest_status "$1")" ]
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
      if [ "$(manifest_status "$f" "$NEW_MANIFEST")" = "created" ]; then
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
    line=$(parse_manifest "$OLD_MANIFEST" | awk '
      { f = substr($0, index($0, " ") + 1) }
      !found && f != "CLAUDE.md" && f != "AGENTS.md" && f != "CLAUDE.local.md" && f != "AGENTS.override.md" {
        target = f; found = 1
      }
      END { if (found) print target }')
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
    if [ -z "$UPDATE_DIR" ]; then
      mkdir -p "$(dirname "$abs")"
    fi
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
  write_models_marker "$PROJECT/factory/.models-sync-needed"
}

write_models_marker() {
  printf '%s\n%s\n' \
    'The WholeTeam installer rewrote the agent files with default models.' \
    'On the next `Let'"'"'s code`, the Orchestrator re-applies the models block of factory/config.yaml and deletes this file.' \
    > "$1"
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
  if [ -n "$UPDATE_DIR" ]; then
    stage_file "$PROJECT/factory/.install-manifest"
    write_content "$NEW_MANIFEST" "$STAGED_TARGET"
  else
    write_content "$NEW_MANIFEST" "$PROJECT/factory/.install-manifest"
  fi
}

# load_old_manifest <mode>: sets OLD_MANIFEST and ROOT_MODE for the root files.
# ROOT_MODE is "update" only when an update finds a non-empty manifest.
load_old_manifest() {
  OLD_MANIFEST=""
  ROOT_MODE="install"
  if [ "$1" = "update" ]; then
    OLD_MANIFEST=$(make_temp)
    if [ -f "$PROJECT/factory/.install-manifest" ]; then
      parse_manifest "$PROJECT/factory/.install-manifest" > "$OLD_MANIFEST"
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
  local line action file
  info "Root files:"
  parse_manifest "$PROJECT/factory/.install-manifest" | while IFS= read -r line; do
    action="${line%% *}"
    file="${line#* }"
    if [ "$action" = "created" ]; then
      info "  created    $file"
    else
      info "  block in   $file"
    fi
  done
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
  local installed rel src dest copied=0 before after tool pattern f runtime
  installed=$(tr -d ' \r\n' < "$PROJECT/factory/core/VERSION")
  info ""
  info "Updating WholeTeam $installed -> $VERSION in $PROJECT ..."

  # mkdir reserves the journal name; never reuse or delete unrelated contents.
  mkdir "$PROJECT/factory/.wholeteam-update"
  UPDATE_DIR="$PROJECT/factory/.wholeteam-update"
  runtime=unix
  case "$OSTYPE" in msys*|cygwin*) runtime=bash ;; esac
  printf '%s %s\n' "$runtime" "$$" > "$UPDATE_DIR/owner"
  printf '%s\n' 'wholeteam-update-v1' > "$UPDATE_DIR/format"
  UPDATE_COUNT=0
  stage_target "$PROJECT/factory/core"
  for f in FACTORY.md MIGRATIONS.md config.defaults.yaml; do
    [ -s "$TEMPLATE/factory/core/$f" ] || die "The replacement core is missing $f."
  done
  cp -pR "$TEMPLATE/factory/core" "$STAGED_TARGET"
  validate_copy "$TEMPLATE/factory/core" "$STAGED_TARGET"
  printf '%s\n' "$VERSION" > "$STAGED_TARGET/VERSION"

  for tool in .claude .codex; do
    case "$tool" in .claude) pattern='factory-*.md' ;; .codex) pattern='factory-*.toml' ;; esac
    for src in "$TEMPLATE/root/$tool/agents/"$pattern; do
      [ -f "$src" ] || die "The replacement $tool agents are missing."
      stage_target "$PROJECT/$tool/agents/${src##*/}"
      cp -p "$src" "$STAGED_TARGET"
      validate_copy "$src" "$STAGED_TARGET"
    done
    for f in "$PROJECT/$tool/agents/"$pattern; do
      [ -f "$f" ] || continue
      if [ ! -f "$TEMPLATE/root/$tool/agents/${f##*/}" ]; then
        stage_target "$f"
      fi
    done
  done
  stage_file "$PROJECT/factory/.models-sync-needed"
  write_models_marker "$STAGED_TARGET"

  before=""
  if is_tracked ".gitignore"; then
    before=$(git -C "$PROJECT" diff --quiet -- .gitignore && printf 'clean' || printf 'dirty')
  fi
  apply_root_files "$ROOT_MODE"

  while IFS= read -r rel; do
    rel="${rel#./}"
    src="$TEMPLATE/factory/$rel"
    dest="$PROJECT/factory/$rel"
    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
      stage_target "$dest"
      cp -p "$src" "$STAGED_TARGET"
      validate_copy "$src" "$STAGED_TARGET"
      copied=$((copied + 1))
      info "  added missing starting file factory/$rel"
    fi
  done <<EOF
$(cd "$TEMPLATE/factory" && find . -type f ! -path './core/*' | sort)
EOF

  promote_update
  if [ "$before" = "clean" ]; then
    after=$(git -C "$PROJECT" diff --quiet -- .gitignore && printf 'clean' || printf 'dirty')
    if [ "$after" = "dirty" ]; then
      info "  The WholeTeam block in .gitignore changed. Commit it:"
      info "    git add .gitignore && git commit -m \"chore: update WholeTeam ignore rules\""
    fi
  fi

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
  [ -n "$VERSION" ] || die "The replacement VERSION is empty."

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

  recover_update || die "Cannot recover the previous update. Its backup has been kept."

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

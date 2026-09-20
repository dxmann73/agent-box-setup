#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  echo "usage: init-plans.sh <target-repo>" >&2
  exit 2
}

die() {
  echo "init-plans: $*" >&2
  exit 1
}

unix_millis() {
  local ns
  ns=$(date +%s%N)
  [[ "$ns" =~ ^[0-9]+$ ]] || die "date did not return epoch nanoseconds: $ns"
  printf '%s\n' "$((ns / 1000000))"
}

stamp_name() {
  local base=$1
  local ms=$2
  local stem
  if [[ "$base" == *.* ]]; then
    stem=${base%.*}
    if [[ -n "$stem" && "$stem" != "." ]]; then
      printf '%s-%s.%s\n' "$stem" "$ms" "${base##*.}"
      return
    fi
  fi
  printf '%s-%s\n' "$base" "$ms"
}

[[ $# -eq 1 ]] || usage

target=$1
[[ -n "$target" ]] || usage
[[ -d "$target" ]] || die "target is not an existing directory: $target"

target=$(cd "$target" && pwd)
plans_dir=$target/_plans
drafts_dir=$plans_dir/drafts

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
asset_readme=$script_dir/../assets/README.md
[[ -f "$asset_readme" ]] || die "missing template: $asset_readme"

stages=(drafts next open done discarded)
incoming_names=(plans _incoming incoming)

is_initialized() (
  local name path extra=()
  [[ -d "$plans_dir" && -f "$plans_dir/README.md" ]] || return 1
  for name in "${stages[@]}"; do
    [[ -d "$plans_dir/$name" ]] || return 1
  done

  shopt -s nullglob
  for path in "$plans_dir"/*; do
    name=$(basename "$path")
    case "$name" in
      README.md | drafts | next | open | done | discarded) ;;
      *) extra+=("$name") ;;
    esac
  done
  ((${#extra[@]} == 0))
)

if [[ -e "$plans_dir" ]]; then
  if is_initialized; then
    echo "_plans/ already initialized at $plans_dir"
    if ! cmp -s "$plans_dir/README.md" "$asset_readme"; then
      echo "note: _plans/README.md differs from the current plan-init template"
      echo "suggestion: reconcile lifecycle phases, transitions, indexes, and repository rules"
      echo "init-plans: review manually; existing _plans/README.md left unchanged"
    fi
    exit 0
  fi
  die "$plans_dir exists but is not the plan-init layout; refusing to change it"
fi

declare -a incoming_dirs=()
for name in "${incoming_names[@]}"; do
  path=$target/$name
  if [[ -e "$path" ]]; then
    [[ -d "$path" ]] || die "$path exists but is not a directory"
    incoming_dirs+=("$path")
  fi
done

declare -A from_by_dest=()

dest_name_taken() {
  local name=$1
  [[ -n "${from_by_dest[$name]+x}" || -e "$drafts_dir/$name" ]]
}

unique_dest_name() {
  local original=$1
  local candidate=$original
  local ms
  if dest_name_taken "$candidate"; then
    ms=$(unix_millis)
    candidate=$(stamp_name "$original" "$ms")
    while dest_name_taken "$candidate"; do
      ms=$((ms + 1))
      candidate=$(stamp_name "$original" "$ms")
    done
  fi
  printf '%s\n' "$candidate"
}

renamed=0
for source in "${incoming_dirs[@]+"${incoming_dirs[@]}"}"; do
  while IFS= read -r -d '' path; do
    base=$(basename "$path")
    [[ "$base" == .gitkeep ]] && continue
    dest=$(unique_dest_name "$base")
    if [[ "$dest" != "$base" ]]; then
      renamed=$((renamed + 1))
    fi
    from_by_dest[$dest]=$path
  done < <(find "$source" -mindepth 1 -maxdepth 1 -print0)
done

mkdir -p "$plans_dir"
for name in "${stages[@]}"; do
  mkdir -p "$plans_dir/$name"
done

if ((${#from_by_dest[@]} > 0)); then
  for dest in "${!from_by_dest[@]}"; do
    mv -- "${from_by_dest[$dest]}" "$drafts_dir/$dest"
  done
fi

for source in "${incoming_dirs[@]+"${incoming_dirs[@]}"}"; do
  rm -f -- "$source/.gitkeep"
  rmdir -- "$source" || die "$source was not empty after moving its files into drafts/"
done

for name in "${stages[@]}"; do
  shopt -s nullglob dotglob
  entries=("$plans_dir/$name"/*)
  shopt -u nullglob dotglob
  if ((${#entries[@]} == 0)); then
    : >"$plans_dir/$name/.gitkeep"
  fi
done
cp -- "$asset_readme" "$plans_dir/README.md"

if ((${#from_by_dest[@]} > 0)); then
  if ((renamed > 0)); then
    echo "initialized $plans_dir (moved ${#from_by_dest[@]} item(s) into drafts/, $renamed renamed with unix ms)"
  else
    echo "initialized $plans_dir (moved ${#from_by_dest[@]} item(s) into drafts/)"
  fi
else
  echo "initialized $plans_dir"
fi

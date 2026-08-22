#!/bin/sh

# POSIX sh: walk a root dir, find git working trees, fetch all remotes and prune.
ROOT=${1:-.}

# Find ".git" markers (dir or file), turn them into repo dirs (parent),
# de-dup with sort -u, then iterate.
find "$ROOT" -mindepth 1 \( -type d -name .git -o -type f -name .git \) -print 2>/dev/null \
  | sed 's:/\.git$::' \
  | sort -u \
  | while IFS= read -r repo
    do
      [ -n "$repo" ] || continue
      echo "==========================="
      echo "==> $repo"
      # Run everything in a subshell so we don't change the caller's cwd
      (
        cd "$repo" || exit 0
        # Ensure it's a git working tree (skip weird matches)
        git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

        # Fetch all remotes and prune stale remote-tracking refs
        git fetch --all --prune --prune-tags

        # Determine current branch (skip detached HEAD)
        branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || exit 0

        # Keep local main aligned with origin/main (fetch already ran).
        # -f moves main to match origin/main
        # even when main had diverged (discarding local-only commits on main).
        if [ "$branch" != "main" ]; then
          echo "   Updating local main from origin/main"
          git branch -f main origin/main
        fi

        # Ensure branch has an upstream
        upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null) || exit 0

        # Check for local changes (staged, unstaged, untracked)
        if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
          echo "   Stashing changes"
          git stash push -u -m "auto-stash before pull" >/dev/null 2>&1
          stashed=1
        else
          stashed=0
        fi

        echo "   Pulling $branch"
        git pull --ff-only

        # On main: remove other local branches merged into main. Before stash pop so local edits
        # stay in the stash during this step.
        if [ "$branch" = "main" ]; then
          git branch --merged main --format='%(refname:short)' 2>/dev/null \
            | while IFS= read -r b; do
                [ "$b" = main ] && continue
                echo "   Removing merged branch $b"
                git branch -d "$b" || echo "   WARNING: could not delete branch $b"
              done
        fi

        # Restore stash if we created one
        if [ "$stashed" -eq 1 ]; then
          echo "   Restoring stash"
          git stash pop >/dev/null 2>&1 || {
            echo "   WARNING: stash pop had conflicts in $repo"
          }
        fi
      )
    done


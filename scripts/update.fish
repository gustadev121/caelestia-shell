#!/usr/bin/env fish

set REPO_DIR (status dirname)/..
cd $REPO_DIR

# Determine current branch (default to custom)
set CURRENT_BRANCH (git branch --show-current 2>/dev/null)
if test -z "$CURRENT_BRANCH"
    set CURRENT_BRANCH "custom"
end

notify-send -a "Caelestia" -i "system-software-update" "Caelestia Update" "Checking for updates on branch '$CURRENT_BRANCH'..."

# Fetch official upstream and fork origin
git fetch upstream main --quiet 2>/dev/null
git fetch origin --quiet 2>/dev/null

# Check if there are updates to apply
set COMMITS_BEHIND (git rev-list --count HEAD..upstream/main 2>/dev/null)
if test -z "$COMMITS_BEHIND"; or test "$COMMITS_BEHIND" -eq 0
    notify-send -a "Caelestia" -i "emblem-default" "Caelestia Update" "Already up to date with upstream/main!"
    exit 0
end

# Check for uncommitted working tree changes
set HAS_DIRTY (git status --porcelain 2>/dev/null)
set STASHED 0
if test -n "$HAS_DIRTY"
    git stash push -m "Auto-stashed before caelestia update" --quiet
    set STASHED 1
end

# Rebase local branch onto upstream/main
if not git rebase upstream/main
    git rebase --abort
    if test $STASHED -eq 1
        git stash pop --quiet
    end
    notify-send -u critical -a "Caelestia" -i "dialog-error" \
        "Caelestia Update Failed" \
        "Merge conflict encountered with upstream/main. Rebase was aborted to protect your changes. Please resolve manually."
    exit 1
end

# Restore stashed changes if any were saved
if test $STASHED -eq 1
    git stash pop --quiet
end

# Recompile plugins if ninja build files exist
if test -f "$REPO_DIR/build/build.ninja"
    ninja -C "$REPO_DIR/build" --quiet 2>/dev/null
end

# Push rebased branch to your personal fork (gustadev121/shell)
git push origin $CURRENT_BRANCH --force-with-lease --quiet 2>/dev/null

# Restart Caelestia Quickshell instances
caelestia shell -k
sleep 1
caelestia shell -d

notify-send -a "Caelestia" -i "emblem-default" \
    "Caelestia Updated Successfully" \
    "Applied $COMMITS_BEHIND commit(s) from upstream and restarted Caelestia!"

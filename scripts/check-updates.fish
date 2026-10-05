#!/usr/bin/env fish

set REPO_DIR (status dirname)/..
cd $REPO_DIR

# Fetch latest upstream without touching local working tree
git fetch upstream main --quiet 2>/dev/null

# Count commits behind upstream/main
set COMMITS_BEHIND (git rev-list --count HEAD..upstream/main 2>/dev/null)

if test -n "$COMMITS_BEHIND"; and test "$COMMITS_BEHIND" -gt 0
    set COMMITS_LOG (git log -n 3 --pretty=format:"• %s" HEAD..upstream/main 2>/dev/null)
    
    # Send notification with action button to trigger the updater
    set ACTION (notify-send -a "Caelestia" \
                            -i "software-update-available" \
                            -u normal \
                            -t 60000 \
                            -A "update=Update Now" \
                            "Caelestia Update Available" \
                            "$COMMITS_BEHIND new commit(s) on upstream/main:\n$COMMITS_LOG")

    if test "$ACTION" = "update"
        fish "$REPO_DIR/scripts/update.fish"
    end
end

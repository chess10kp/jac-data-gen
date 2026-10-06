#!/usr/bin/env bash
# Harvest newly-green jachacks repos: mirror .jac files to data/jachacks_repaired/,
# rsync back to clarity2 check tree, commit + push to origin.
# Runs one sweep; the caller loops.
set -u
REPO_ROOT=/home/jac/repos/jac_llm_data
TREE=$REPO_ROOT/data/jachacks_nonsf
MIRROR=$REPO_ROOT/data/jachacks_repaired
STATE=/tmp/jachacks_green.txt
JAC=/home/jac/.local/bin/jac.bak-0.36.1
REMOTE=clarity2:/home/madhu/jachacks_check/jachacks_nonsf

touch "$STATE"
cd "$TREE" || exit 1
newly=()
# only the 71 repos that had failures (from the group partition files)
mapfile -t CANDIDATES < <(grep -h '^## ' "$REPO_ROOT"/data/jachacks_failing_group*.txt | sed 's/^## //; s/ .*//')
for repo in "${CANDIDATES[@]}"; do
  [ -d "$repo" ] || continue
  grep -qx "$repo" "$STATE" && continue
  out=$("$JAC" check -j 8 "$repo" 2>&1)
  footer=$(echo "$out" | tail -1)
  # green iff footer reports passes and no nonzero "N failed"
  echo "$footer" | grep -q "passed" || continue
  echo "$footer" | grep -qE "(^|[^0-9])[1-9][0-9]* failed" && continue
  echo "GREEN: $repo   [$footer]"
  newly+=("$repo")
  # mirror .jac files into data/jachacks_repaired/<repo>/
  (cd "$repo" && find . -name '*.jac' -print0 |
    tar --null -cf - -T -) | tar -xf - -C "$MIRROR/$repo" --no-same-owner 2>/dev/null || {
    mkdir -p "$MIRROR/$repo"
    (cd "$repo" && find . -name '*.jac' -exec cp --parents {} "$MIRROR/$repo/" \;)
  }
  # push back to clarity2 check tree (jac files only; --delete handles renames)
  rsync -az --timeout=120 --delete \
    --include='*/' --include='*.jac' --exclude='*' \
    "$repo/" "$REMOTE/$repo/" 2>&1 | grep -v "WARNING\|vulnerable\|openssh\|upgraded"
  echo "$repo" >> "$STATE"
done

if [ ${#newly[@]} -gt 0 ]; then
  cd "$REPO_ROOT"
  git add data/jachacks_repaired .gitignore 2>/dev/null
  git add data/jachacks_failing_group*.txt data/jachacks_agent*_status.md 2>/dev/null
  repos_csv=$(IFS=,; echo "${newly[*]}")
  git commit -m "$(cat <<EOF
data(jachacks): repair sweep — ${#newly[@]} repo(s) green on jac check 0.36.1

Repos: $repos_csv
Mirrored to data/jachacks_repaired/ and pushed to clarity2 check tree.

Generated with [Devin](https://devin.ai)

Co-Authored-By: Devin <158243242+devin-ai-integration[bot]@users.noreply.github.com>
EOF
)" && git push origin master
fi

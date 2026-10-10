#!/usr/bin/env bash
# CI smoke: jac installed, check + run a tiny program per shard.
set -euo pipefail
d=$(mktemp -d); cd "$d"
printf 'with entry { print("shard %s ok"); }\n' "$SHARD" > main.jac
jac check main.jac && jac run main.jac | tee "$GITHUB_WORKSPACE/$OUT/shard_$SHARD.txt"

#!/usr/bin/env bash
# Grade the 08 and base function-eval predictions under jac 0.36.1.
#
#   ./run.sh                    full run, both models
#   SMOKE=6 ./run.sh            first 6 tasks per model only (setup check, ~1 min)
#   MODELS=08 ./run.sh          one model only
#   WORKERS=8 ./run.sh          grader threads (default 4)
#   JAC=/path/to/jac ./run.sh   use a jac 0.36.1 binary you already have
set -euo pipefail
cd "$(dirname "$0")"
VER=0.36.1

if [ -z "${JAC:-}" ]; then
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) PLAT=macos-aarch64 ;;
    Darwin-x86_64) PLAT=macos-x86_64 ;;
    Linux-x86_64) PLAT=linux-x86_64 ;;
    Linux-aarch64 | Linux-arm64) PLAT=linux-aarch64 ;;
    *) echo "unsupported platform $(uname -sm); download jac $VER yourself and set JAC=" >&2; exit 1 ;;
  esac
  JAC="$PWD/bin/jac-$VER"
  if [ ! -x "$JAC" ]; then
    URL="https://github.com/jaseci-labs/jac/releases/download/v$VER/jac-$VER-$PLAT"
    echo "downloading $URL (~200 MB)"
    mkdir -p bin
    curl -fL --progress-bar -o "$JAC.part" "$URL"
    want=$(curl -fsSL "$URL.sha256" | cut -d' ' -f1)
    got=$( (sha256sum "$JAC.part" 2>/dev/null || shasum -a 256 "$JAC.part") | cut -d' ' -f1)
    [ "$want" = "$got" ] || { echo "sha256 mismatch: want $want, got $got" >&2; rm -f "$JAC.part"; exit 1; }
    chmod +x "$JAC.part" && mv "$JAC.part" "$JAC"
  fi
fi
"$JAC" --version 2>&1 | grep -q "$VER" || { echo "$JAC is not jac $VER: $("$JAC" --version 2>&1 | head -1)" >&2; exit 1; }

# Same settings as the original 0.36.1 cross-check: 0.36.1's `jac test` runs pytest,
# 2 xdist workers per test run, 900 s per stage (big tasks have 60+ test blocks).
export PYTEST_XDIST_AUTO_NUM_WORKERS=2
for m in ${MODELS:-08 base}; do
  S="preds/${m}_samples.jsonl"
  OUT="out/$m"
  if [ -n "${SMOKE:-}" ]; then
    OUT="out/smoke_$m"
    mkdir -p "$OUT"
    head -n "$SMOKE" "$S" > "$OUT/samples.jsonl"
    S="$OUT/samples.jsonl"
  fi
  mkdir -p "$OUT"
  echo "$(date '+%H:%M:%S') grading $m -> $OUT (log: $OUT/grade.log)"
  python3 eval/eval_jac.py --problems eval/test.jsonl --samples "$S" --out-dir "$OUT" \
    --jac-bin "$JAC" --k 1 --workers "${WORKERS:-4}" --timeout 900 > "$OUT/grade.log" 2>&1 \
    || echo "grader exit $? for $m, see $OUT/grade.log"
  python3 - "$OUT/summary.json" <<'PY'
import json, sys
o = json.load(open(sys.argv[1]))["overall"]
print("  ", {k: o.get(k) for k in ("samples", "task_success_rate", "check_rate", "behavior_test_rate", "status_counts", "complete")})
PY
done
echo "$(date '+%H:%M:%S') done. Send back the out/ folder."

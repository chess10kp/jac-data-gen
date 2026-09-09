#!/usr/bin/env bash
# Resume OSP generation on the luna model via the unified backend
# (osp_generate.py --task idiomize --backend pi -- any model just works).
# Preferred entrypoint: osp_generate.py (one seam for pi/cursor/zen/openrouter).
# Legacy direct call `osp_agent_generate.py` still works but now routes via llm_backend too.
# Fixes vs /tmp/resume_osp_luna_patched.sh:
#   - validate uses --append (no manifest truncation, no pg_reset between batches)
#   - pack uses --trust-manifests like run_osp_wave.sh
set -uo pipefail
cd /home/jac/repos/jac_llm_data
export CURSOR_OSP_TRIES="${CURSOR_OSP_TRIES:-3}"
MODEL="${OSP_MODEL:-gpt-5.6-luna}"
BACKEND="${OSP_BACKEND:-pi}"
BATCHES=("${@:-}")
if [[ ${#BATCHES[@]} -eq 0 ]]; then BATCHES=(35 36 37 38 39 40 41); fi
LOG=/tmp/osp_luna_pi_$(date +%Y%m%d_%H%M%S).log
echo "OSP idiomize via $BACKEND/$MODEL -> $LOG (tries=$CURSOR_OSP_TRIES)"
for b in "${BATCHES[@]}"; do
  echo "===== BATCH $b $(date) [$BACKEND/$MODEL] =====" | tee -a "$LOG"
  python3 scripts/gen/osp_generate.py --task idiomize --backend "$BACKEND" --model "$MODEL" --batch "$b" --flow jac-only 2>&1 | tee -a "$LOG"
  python3 scripts/ops/sequential_validate_manifest.py "$b" --append 2>&1 | tee -a "$LOG" \
    || echo "validate $b had failures" | tee -a "$LOG"
  python3 scripts/gen/pack_osp_lifts.py --trust-manifests 2>&1 | tail -n 5 | tee -a "$LOG" || true
done
echo "DONE $(date) log $LOG"

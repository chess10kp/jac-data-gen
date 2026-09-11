#!/bin/bash
# Validate one issue_gen record end-to-end. Usage: ./validate.sh <stem>
stem="$1"
cd /home/jac/repos/jac_llm_data/data/osp_lifts || exit 1
fail=0
python3 "issue_gen/${stem}.ref.py" >/dev/null 2>&1 && echo "REF  ok" || { echo "REF  FAIL"; fail=1; }
jac check "issue_gen/${stem}.jac" >/dev/null 2>&1 && echo "CHK  ok" || { echo "CHK  FAIL"; jac check "issue_gen/${stem}.jac" 2>&1 | head -20; fail=1; }
jac test "issue_gen/${stem}_guard.jac" >/dev/null 2>&1 && echo "TST  ok" || { echo "TST  FAIL"; jac test "issue_gen/${stem}_guard.jac" 2>&1 | grep -E "FAIL|Error|error|passed|failed" | head -20; fail=1; }
exit $fail

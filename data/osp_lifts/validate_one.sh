#!/bin/bash
# Validate one record stem: ref.py, jac check, jac test, py2jac floor.
# Usage: ./validate_one.sh <stem>
cd "$(dirname "$0")" || exit 1
S="$1"
ok=0; fail=0
if python3 "issue_gen/${S}.ref.py" >/tmp/v_${S}.ref 2>&1; then echo "ref    OK"; else echo "ref    FAIL"; cat /tmp/v_${S}.ref; fail=1; fi
if jac check "issue_gen/${S}.jac" >/tmp/v_${S}.chk 2>&1; then echo "check  OK"; else echo "check  FAIL"; cat /tmp/v_${S}.chk; fail=1; fi
if jac test "issue_gen/${S}_guard.jac" >/tmp/v_${S}.tst 2>&1; then echo "test   OK"; else echo "test   FAIL"; tail -30 /tmp/v_${S}.tst; fail=1; fi
# floor: transpile, sanitize, check
jac tool py2jac "issue_gen/${S}.py" > "/tmp/v_${S}.floor" 2>/dev/null
if [ -s "/tmp/v_${S}.floor" ]; then
  # sanitize: drop def-body docstring artifacts are left as-is; try check directly
  cp "/tmp/v_${S}.floor" "issue_gen/${S}.floor.jac"
  if jac check "issue_gen/${S}.floor.jac" >/tmp/v_${S}.fchk 2>&1; then echo "floor  generated"; else echo "floor  port_failed"; rm -f "issue_gen/${S}.floor.jac"; fi
else
  echo "floor  port_failed (no output)"
fi
exit $fail

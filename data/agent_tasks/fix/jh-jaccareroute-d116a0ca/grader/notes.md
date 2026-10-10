# jh-jaccareroute-d116a0ca

Source: jachacks_spring. Level 4.

Starter at jac 0.37.25: 26 errors in 1 file(s); codes {'E1036': 12, 'E2086': 5, 'E0013': 4, 'E0002': 2, 'E0001': 1, 'E0004': 1, 'E1053': 1}.

Sample diagnostics:
- `E0013 backend/main.jac:250 'match' is a keyword and cannot be used as a ability name`
- `E0013 backend/main.jac:266 'match' is a keyword and cannot be used as a ability name`
- `E0013 backend/main.jac:282 'match' is a keyword and cannot be used as a ability name`
- `E0013 backend/main.jac:360 'graph' is a keyword and cannot be used as a variable name`
- `E0001 backend/main.jac:365 Expected '{', got ','`
- `E0002 backend/main.jac:366 Missing ';'`
- `E0004 backend/main.jac:366 Unexpected token in expression: ':'`
- `E0002 backend/main.jac:376 Missing '}'`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-jaccareroute-d116a0ca <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.047 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.408 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0

# jh-graphpilot-jac-29b5e048

Source: jachacks_spring. Level 5.

Starter at jac 0.36.1: 43 errors in 1 file(s); codes {'E0046': 14, 'E1032': 7, 'E1053': 7, 'E0001': 4, 'E0002': 4, 'E0005': 4, 'E1116': 2, 'E1055': 1}.

Sample diagnostics:
- `E0001 backend/jac/graphpilot.jac:27 Expected 'entry | exit', got '{'`
- `E0002 backend/jac/graphpilot.jac:28 Missing ';'`
- `E0046 backend/jac/graphpilot.jac:28 Unexpected token in archetype body`
- `E0046 backend/jac/graphpilot.jac:28 Unexpected token in archetype body`
- `E0046 backend/jac/graphpilot.jac:28 Unexpected token in archetype body`
- `E0005 backend/jac/graphpilot.jac:30 Unexpected token '}'`
- `E0001 backend/jac/graphpilot.jac:37 Expected 'entry | exit', got '{'`
- `E0002 backend/jac/graphpilot.jac:38 Missing ';'`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-graphpilot-jac-29b5e048 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.055 body=1.216 min_file_body=1.216
- stub: pass=False check=True sym=1.0 mass=0.661 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0

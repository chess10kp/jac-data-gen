# jh-jachacks-idea-to-prototype-0c46f002

Source: jachacks_spring. Level 4.

Starter at jac 0.36.1: 19 errors in 1 file(s); codes {'E0005': 6, 'E0030': 6, 'E1001': 4, 'E0002': 2, 'E1032': 1}.

Sample diagnostics:
- `E0002 main.jac:6 Missing ';'`
- `E0005 main.jac:6 Unexpected token ':'`
- `E0030 main.jac:6 Unexpected semicolon at module level`
- `E0002 main.jac:7 Missing ';'`
- `E0005 main.jac:7 Unexpected token ':'`
- `E0030 main.jac:7 Unexpected semicolon at module level`
- `E0005 main.jac:23 Unexpected token '"""You are Scout, a senior product thinking AI.`
- `E0030 main.jac:31 Unexpected semicolon at module level`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-jachacks-idea-to-prototype-0c46f002 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.054 body=1.0 min_file_body=1.0
- starter_profile: pass=False check=None sym=0.692 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.712 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0

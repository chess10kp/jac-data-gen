# jh-outloop-ai-4ae5a4b3

Source: jachacks_2026. Level 5.

Starter at jac 0.37.25: 35 errors in 4 file(s); codes {'E0002': 12, 'E0004': 8, 'E0001': 4, 'E0013': 4, 'E1122': 4, 'E0049': 3}.

Sample diagnostics:
- `E0004 env_loader.jac:16 Unexpected token in expression: '|'`
- `E0001 env_loader.jac:16 Expected '{', got 'NAME'`
- `E0004 env_loader.jac:16 Unexpected token in expression: '.'`
- `E0002 env_loader.jac:16 Missing ';'`
- `E0002 env_loader.jac:16 Missing ';'`
- `E0013 env_loader.jac:17 'continue' is a keyword and cannot be used as a variable name`
- `E0002 env_loader.jac:17 Missing '}'`
- `E0049 agent1_lookout.jac:110 'root()' was removed. Use bare 'root' instead.`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-outloop-ai-4ae5a4b3 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.016 body=1.001 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.458 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0

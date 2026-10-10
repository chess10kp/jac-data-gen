# jh-outloop-ai-8126a4f5

Source: jachacks_2026. Level 5.

Starter at jac 0.36.1: 19 errors in 8 file(s); codes {'E0049': 7, 'E0002': 6, 'E0004': 4, 'E0001': 2}.

Sample diagnostics:
- `E0004 env_loader.jac:16 Unexpected token in expression: '|'`
- `E0001 env_loader.jac:16 Expected '{', got 'NAME'`
- `E0004 env_loader.jac:16 Unexpected token in expression: '.'`
- `E0002 env_loader.jac:16 Missing ';'`
- `E0002 env_loader.jac:16 Missing ';'`
- `E0002 env_loader.jac:17 Missing '}'`
- `E0049 agent5_software_prompt.jac:82 'root()' was removed. Use bare 'root' instead.`
- `E0049 agent4_problem_creator.jac:89 'root()' was removed. Use bare 'root' instead.`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-outloop-ai-8126a4f5 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.013 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.468 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0

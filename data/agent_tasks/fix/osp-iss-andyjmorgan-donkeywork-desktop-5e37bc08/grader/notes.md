# osp-iss-andyjmorgan-donkeywork-desktop-5e37bc08

Source: osp_repair_code_fix. Level 3.

Starter at jac 0.37.25: 7 errors in 1 file(s); codes {'E2086': 3, 'E0003': 1, 'E0001': 1, 'E0004': 1, 'E0027': 1}.

Sample diagnostics:
- `E0003 main.jac:111 Expected identifier, got '+'`
- `E0001 main.jac:111 Expected '=', got '+'`
- `E0004 main.jac:111 Unexpected token in expression: '>'`
- `E0027 main.jac:111 Expected ':+>' to close forward typed connection -- did you mean '+>: <EdgeType> :+> <node>'?`
- `E2086 main.jac:29 Edge 'Contains' declares no endpoints, so every traversal through it widens to 'any'`
- `E2086 main.jac:33 Edge 'Runs' declares no endpoints, so every traversal through it widens to 'any'`
- `E2086 main.jac:37 Edge 'AttachedTo' declares no endpoints, so every traversal through it widens to 'any'`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-iss-andyjmorgan-donkeywork-desktop-5e37bc08 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.037 body=1.0 min_file_body=1.0 test=True
- starter_profile: pass=False check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0 test=False
- stub: pass=False check=True sym=1.0 mass=0.734 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.

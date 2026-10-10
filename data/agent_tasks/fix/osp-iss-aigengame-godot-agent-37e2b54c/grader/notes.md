# osp-iss-aigengame-godot-agent-37e2b54c

Source: osp_repair_code_fix. Level 3.

Starter at jac 0.37.25: 7 errors in 1 file(s); codes {'E0002': 2, 'E0001': 1, 'E1117': 1, 'E1001': 1, 'E1097': 1, 'E2086': 1}.

Sample diagnostics:
- `E0001 main.jac:48 Expected '{', got 'if'`
- `E0002 main.jac:48 Missing ';'`
- `E0002 main.jac:49 Missing '}'`
- `E1117 main.jac:17 Node/edge ability trigger must be a walker, got "Scene"`
- `E1001 main.jac:48 Cannot assign bool to set[bool]`
- `E1097 main.jac:78 Connection right operand must be a node instance`
- `E2086 main.jac:23 Edge 'Instances' declares no endpoints, so every traversal through it widens to 'any'`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-iss-aigengame-godot-agent-37e2b54c <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.207 body=1.066 min_file_body=1.066 test=True
- starter_profile: pass=False check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0 test=False
- stub: pass=False check=True sym=1.0 mass=0.813 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.

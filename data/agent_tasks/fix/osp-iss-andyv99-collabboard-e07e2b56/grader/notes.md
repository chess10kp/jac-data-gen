# osp-iss-andyv99-collabboard-e07e2b56

Source: osp_repair_code_fix. Level 4.

Starter at jac 0.37.25: 18 errors in 1 file(s); codes {'E1099': 8, 'E2086': 6, 'E1117': 4}.

Sample diagnostics:
- `E1117 main.jac:95 Node/edge ability trigger must be a walker, got "BoardRoute"`
- `E1117 main.jac:96 Node/edge ability trigger must be a walker, got "ColumnRoute"`
- `E1117 main.jac:97 Node/edge ability trigger must be a walker, got "CardRoute"`
- `E1117 main.jac:98 Node/edge ability trigger must be a walker, got "OrgRoute"`
- `E1099 main.jac:138 Cannot access attribute "status" for type "Response | NoneType"; attribute is missing from NoneType`
- `E1099 main.jac:138 Cannot access attribute "body" for type "Response | NoneType"; attribute is missing from NoneType`
- `E1099 main.jac:139 Cannot access attribute "body" for type "Response | NoneType"; attribute is missing from NoneType`
- `E1099 main.jac:145 Cannot access attribute "status" for type "Response | NoneType"; attribute is missing from NoneType`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-iss-andyv99-collabboard-e07e2b56 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.0 min_file_body=1.0 test=True
- starter_profile: pass=False check=None sym=0.947 mass=1.069 body=1.092 min_file_body=1.092 test=False
- stub: pass=False check=True sym=1.0 mass=0.75 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.

# osp-iss-adrianbrowning-prisma-ts-select-04489f80

Source: osp_repair_code_fix. Level 2.

Starter at jac 0.37.25: 2 errors in 1 file(s); codes {'E1036': 1, 'E2086': 1}.

Sample diagnostics:
- `E1036 main.jac:26 Generic type "dict" requires explicit type arguments`
- `E2086 main.jac:17 Edge 'ReportsTo' declares no endpoints, so every traversal through it widens to 'any'`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-iss-adrianbrowning-prisma-ts-select-04489f80 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.159 body=1.2 min_file_body=1.2 test=True
- starter_profile: pass=False check=None sym=0.5 mass=1.0 body=1.0 min_file_body=1.0 test=False
- stub: pass=False check=True sym=1.0 mass=0.806 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.

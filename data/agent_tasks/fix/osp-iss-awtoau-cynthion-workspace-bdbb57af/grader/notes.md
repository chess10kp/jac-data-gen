# osp-iss-awtoau-cynthion-workspace-bdbb57af

Source: osp_repair_code_fix. Level 2.

Starter at jac 0.37.25: 3 errors in 1 file(s); codes {'E2086': 2, 'E1097': 1}.

Sample diagnostics:
- `E1097 main.jac:72 Connection right operand must be a node instance`
- `E2086 main.jac:23 Edge 'DependsOn' declares no endpoints, so every traversal through it widens to 'any'`
- `E2086 main.jac:27 Edge 'VendorBypass' declares no endpoints, so every traversal through it widens to 'any'`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-iss-awtoau-cynthion-workspace-bdbb57af <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.005 body=1.0 min_file_body=1.0 test=True
- starter_profile: pass=False check=None sym=1.0 mass=1.0 body=1.066 min_file_body=1.066 test=False
- stub: pass=False check=True sym=1.0 mass=0.795 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.

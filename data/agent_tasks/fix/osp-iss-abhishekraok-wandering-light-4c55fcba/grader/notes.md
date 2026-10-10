# osp-iss-abhishekraok-wandering-light-4c55fcba

Source: osp_repair_code_fix. Level 3.

Starter at jac 0.37.25: 6 errors in 1 file(s); codes {'E1032': 3, 'E2086': 2, 'E0010': 1}.

Sample diagnostics:
- `E0010 main.jac:85 'pass' is not supported in Jac`
- `E1032 main.jac:166 Type is Unknown, cannot access attribute "revists"`
- `E1032 main.jac:167 Type is Unknown, cannot access attribute "no_ops"`
- `E1032 main.jac:168 Type is Unknown, cannot access attribute "label"`
- `E2086 main.jac:31 Edge 'Applies' declares no endpoints, so every traversal through it widens to 'any'`
- `E2086 main.jac:36 Edge 'Step' declares no endpoints, so every traversal through it widens to 'any'`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-iss-abhishekraok-wandering-light-4c55fcba <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.0 min_file_body=1.0 test=True
- starter_profile: pass=False check=None sym=1.0 mass=1.173 body=1.205 min_file_body=1.205 test=False
- stub: pass=False check=True sym=1.0 mass=0.717 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.

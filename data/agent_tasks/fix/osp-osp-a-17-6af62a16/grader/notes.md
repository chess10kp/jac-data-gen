# osp-osp-a-17-6af62a16

Source: osp_repair_code_fix. Level 1.

Starter at jac 0.37.25: 2 errors in 1 file(s); codes {'E1032': 2}.

Sample diagnostics:
- `E1032 main.jac:43 Type is Unknown, cannot access attribute "title"`
- `E1032 main.jac:43 Type is Unknown, cannot access attribute "priority"`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-osp-a-17-6af62a16 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.0 min_file_body=1.0 test=True
- starter_profile: pass=False check=None sym=1.0 mass=1.2 body=1.324 min_file_body=1.324 test=False
- stub: pass=False check=True sym=1.0 mass=0.8 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.

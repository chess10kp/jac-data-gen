# osp-iss-banso-labs-banso-16487f67

Source: osp_repair_code_fix. Level 1.

Starter at jac 0.36.1: 1 errors in 1 file(s); codes {'E1053': 1}.

Sample diagnostics:
- `E1053 main.jac:127 Cannot assign <Unknown> to parameter 'object' of type str`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-iss-banso-labs-banso-16487f67 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.0 min_file_body=1.0 test=True
- starter_profile: pass=False check=None sym=0.429 mass=2.0 body=2.0 min_file_body=7.462 test=False
- stub: pass=False check=True sym=1.0 mass=0.847 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.

# osp-iss-alandtse-open-shaders-f461dd09

Source: osp_repair_code_fix. Level 2.

Starter at jac 0.36.1: 4 errors in 1 file(s); codes {'E1117': 2, 'E1114': 2}.

Sample diagnostics:
- `E1117 main.jac:42 Node/edge ability trigger must be a walker, got "Root"`
- `E1117 main.jac:47 Node/edge ability trigger must be a walker, got "Setting"`
- `E1114 main.jac:142 Spawn operator requires a walker instance on one side, got "Root" spawn "VRRegistry"`
- `E1114 main.jac:152 Spawn operator requires a walker instance on one side, got "VRRegistry" spawn "VRRegistry"`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-iss-alandtse-open-shaders-f461dd09 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.465 min_file_body=1.465 test=True
- starter_profile: pass=False check=None sym=0.0 mass=1.025 body=1.0 min_file_body=1.0 test=False
- stub: pass=False check=True sym=1.0 mass=0.774 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.

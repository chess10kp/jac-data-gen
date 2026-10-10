# osp-iss-arthurvardevanyan-k8s-gitops-ci-438acb92

Source: osp_repair_code_fix. Level 2.

Starter at jac 0.37.25: 4 errors in 1 file(s); codes {'E2086': 3, 'E1001': 1}.

Sample diagnostics:
- `E1001 main.jac:51 Cannot assign dict to set`
- `E2086 main.jac:38 Edge 'OwnsRule' declares no endpoints, so every traversal through it widens to 'any'`
- `E2086 main.jac:41 Edge 'BindsRole' declares no endpoints, so every traversal through it widens to 'any'`
- `E2086 main.jac:44 Edge 'BindsClusterRole' declares no endpoints, so every traversal through it widens to 'any'`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-iss-arthurvardevanyan-k8s-gitops-ci-438acb92 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.0 min_file_body=1.0 test=True
- starter_profile: pass=False check=None sym=1.0 mass=1.122 body=1.201 min_file_body=1.201 test=False
- stub: pass=False check=True sym=1.0 mass=0.737 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.

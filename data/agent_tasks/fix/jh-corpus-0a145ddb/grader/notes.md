# jh-corpus-0a145ddb

Source: jachacks_2026. Level 1.

Starter at jac 0.37.25: 1 errors in 1 file(s); codes {'E1032': 1}.

Sample diagnostics:
- `E1032 policies/builtin/context_poisoning.jac:55 Type is Unknown, cannot access attribute "CUSTOM"`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-corpus-0a145ddb <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.006 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.624 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=True sym=0.688 mass=0.0 body=0.0 min_file_body=0.0

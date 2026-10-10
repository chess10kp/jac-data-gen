# jhd-symbiont-d1b4a4fa

Source: jachacks_spring_toolchain_drift. Level 4.

Starter at jac 0.37.25: 22 errors in 1 file(s); codes {'E1036': 19, 'E2086': 3}.

Sample diagnostics:
- `E1036 symbiont.jac:34 Generic type "dict" requires explicit type arguments`
- `E1036 symbiont.jac:42 Generic type "dict" requires explicit type arguments`
- `E1036 symbiont.jac:47 Generic type "dict" requires explicit type arguments`
- `E1036 symbiont.jac:50 Generic type "dict" requires explicit type arguments`
- `E1036 symbiont.jac:50 Generic type "dict" requires explicit type arguments`
- `E1036 symbiont.jac:58 Generic type "dict" requires explicit type arguments`
- `E1036 symbiont.jac:67 Generic type "dict" requires explicit type arguments`
- `E1036 symbiont.jac:75 Generic type "dict" requires explicit type arguments`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jhd-symbiont-d1b4a4fa <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.049 body=1.017 min_file_body=1.017
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.385 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0

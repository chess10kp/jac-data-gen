# jhd-medigraph-2c151e41

Source: jachacks_spring_toolchain_drift. Level 5.

Starter at jac 0.37.25: 37 errors in 1 file(s); codes {'E1036': 32, 'E2086': 5}.

Sample diagnostics:
- `E1036 main.jac:278 Generic type "dict" requires explicit type arguments`
- `E1036 main.jac:386 Generic type "dict" requires explicit type arguments`
- `E1036 main.jac:434 Generic type "dict" requires explicit type arguments`
- `E1036 main.jac:499 Generic type "dict" requires explicit type arguments`
- `E1036 main.jac:479 Generic type "dict" requires explicit type arguments`
- `E1036 main.jac:580 Generic type "dict" requires explicit type arguments`
- `E1036 main.jac:833 Generic type "dict" requires explicit type arguments`
- `E1036 main.jac:846 Generic type "dict" requires explicit type arguments`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jhd-medigraph-2c151e41 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.023 body=1.015 min_file_body=1.015
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.272 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0

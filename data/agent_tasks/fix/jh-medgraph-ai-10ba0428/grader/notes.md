# jh-medgraph-ai-10ba0428

Source: jachacks_spring. Level 3.

Starter at jac 0.36.1: 7 errors in 1 file(s); codes {'E1053': 3, 'E1032': 2, 'E1030': 1, 'E1054': 1}.

Sample diagnostics:
- `E1030 main.jac:271 Type "list[str]" has no attribute "slice"`
- `E1054 main.jac:271 No matching overload found for the function call with the given arguments`
- `E1053 main.jac:373 Cannot assign dict[Literal["id"], str | bool] to parameter 'object' of type dict[str, str]`
- `E1053 main.jac:657 Cannot assign object to parameter 'patient' of type Patient`
- `E1053 main.jac:668 Cannot assign object to parameter 'patient' of type Patient`
- `E1032 main.jac:680 Type is Unknown, cannot access attribute "full_report"`
- `E1032 main.jac:694 Type is Unknown, cannot access attribute "triage_result"`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-medgraph-ai-10ba0428 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.003 body=1.003 min_file_body=1.003
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.366 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0

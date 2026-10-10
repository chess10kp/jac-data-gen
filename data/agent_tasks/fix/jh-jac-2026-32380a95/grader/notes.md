# jh-jac-2026-32380a95

Source: jachacks_2026. Level 5.

Starter at jac 0.37.25: 25 errors in 6 file(s); codes {'E1036': 17, 'E1032': 6, 'E2084': 1, 'E1116': 1}.

Sample diagnostics:
- `E1036 nodes/data_nodes.jac:21 Generic type "list" requires explicit type arguments`
- `E1036 nodes/data_nodes.jac:29 Generic type "list" requires explicit type arguments`
- `E1036 nodes/data_nodes.jac:37 Generic type "list" requires explicit type arguments`
- `E1036 nodes/data_nodes.jac:45 Generic type "list" requires explicit type arguments`
- `E1036 nodes/data_nodes.jac:53 Generic type "list" requires explicit type arguments`
- `E1036 nodes/data_nodes.jac:68 Generic type "list" requires explicit type arguments`
- `E1036 agents/timeline_agent.jac:31 Generic type "dict" requires explicit type arguments`
- `E1036 agents/timeline_agent.jac:38 Generic type "dict" requires explicit type arguments`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-jac-2026-32380a95 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.052 body=1.03 min_file_body=1.0
- starter_profile: pass=True check=None sym=0.912 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.211 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=True sym=0.088 mass=0.0 body=0.0 min_file_body=0.0

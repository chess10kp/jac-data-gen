# jh-jachacks2026-594d2026

Source: jachacks_spring. Level 3.

Starter at jac 0.36.1: 5 errors in 3 file(s); codes {'E1002': 3, 'E-file': 2}.

Sample diagnostics:
- `E-file components/Sidebar.cl.jac:None Error checking 'components/Sidebar.cl.jac': components/Sidebar.cl.jac: the .cl.jac marker was retired -- rename the file`
- `E-file pages/AgentActivityPage.cl.jac:None Error checking 'pages/AgentActivityPage.cl.jac': pages/AgentActivityPage.cl.jac: the .cl.jac marker was retired -- renam`
- `E1002 services/appService.jac:201 Cannot return <Unknown>, expected Goal`
- `E1002 services/appService.jac:240 Cannot return <Unknown>, expected Mission`
- `E1002 services/appService.jac:283 Cannot return <Unknown>, expected MemoryEntry`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-jachacks2026-594d2026 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.001 body=1.001 min_file_body=1.0
- starter_profile: pass=True check=None sym=0.974 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.171 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0

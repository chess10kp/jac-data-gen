# nat-l3-greenhouse-watering
Persistence: run gate seeds in one process and reads in a second (needs jac.toml: without a project, jac run does not persist root across processes in 0.37.25).
Dir-negative module_state_store keeps state in a glob dict -> must be killed (by tests and/or run gate).
Alternative: node-side Bed ability for WaterBed, visit-else get-or-create, eager DueOn.
- jac 0.36.1 port: alt: `visit here ++> Bed(...)` crashes the 0.36.1 compiler (ConnectOp has no attribute name) -> bind then visit. module_state_store mutant retyped (bare/any list typing).

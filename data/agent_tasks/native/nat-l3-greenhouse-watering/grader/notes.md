# nat-l3-greenhouse-watering
Persistence: run gate seeds in one process and reads in a second (needs jac.toml: without a project, jac run does not persist root across processes in 0.37.25).
Dir-negative module_state_store keeps state in a glob dict -> must be killed (by tests and/or run gate).
Alternative: node-side Bed ability for WaterBed, visit-else get-or-create, eager DueOn.

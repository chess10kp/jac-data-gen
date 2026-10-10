I want to model our company org chart as a Jac graph. Put it in `orgchart.jac`.

Model:
- `node Employee` with `name: str`, `title: str`, `salary: int`
- `edge Manages` going from a manager to each of their direct reports (no fields needed)

Walkers (each is spawned directly on an `Employee` node and should `report` its answer exactly once):
- `Headcount` — how many people are under this employee, at every level below them (don't count the employee themselves). Reports an int.
- `PayrollTotal` — combined salary of this employee plus everyone under them. Reports an int.
- `ChainOfCommand` — the names from this person's direct manager up to the top of the company, nearest first. Reports a list of strings (empty for the CEO).

The graph is built in memory by whoever uses the module (e.g. `ceo +>:Manages:+> vp;`), so nothing needs to persist. A quick demo under `with entry:__main__` would be nice but optional.

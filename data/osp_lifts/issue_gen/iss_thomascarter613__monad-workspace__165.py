"""Dependency graph and impact analysis foundation.

Files belong to components, tasks depend on components, and tests cover
tasks; when a file changes, the blast radius is the owning components,
every task that depends on an impacted component, and the tests covering
those tasks (E25's changed-file impact analysis and impacted verification
recommendation). The chain below is hand-rolled: the model is three
dict-of-lists maps, and every hop of the ripple is a full reverse sweep
over one of them -- scanning every component's file list for each changed
file, then every task's component list, then every test's task list --
chained together with sets. No reverse index exists, so each lookup is a
linear scan of the whole map.
Ref: thomascarter613/monad-workspace#165
"""


def impacted(model, changed_files):
    """Changed-file impact analysis.

    ``model`` holds ``{"components": {comp: [files]}, "tasks": {task:
    [components]}, "tests": {test: [tasks]}}``. Returns
    ``{"components": sorted, "tasks": sorted, "tests": sorted}`` for the
    ripple file -> owning components -> depending tasks -> covering tests.
    A changed file belonging to no component has no impact.
    """
    comps = _owners(model["components"], changed_files)
    tasks = _dependents(model["tasks"], comps)
    tests = _dependents(model["tests"], tasks)
    return {"components": sorted(comps), "tasks": sorted(tasks), "tests": sorted(tests)}


def recommend_tests(model, changed_files):
    """Recommended verification for a change: tests covering impacted tasks."""
    return impacted(model, changed_files)["tests"]


def _owners(components, files):
    """Reverse sweep: components whose file list contains any changed file."""
    hit = set()
    for comp, owned in components.items():
        for f in files:
            if f in owned:
                hit.add(comp)
    return hit


def _dependents(mapping, targets):
    """Reverse sweep: keys whose value list intersects ``targets``."""
    hit = set()
    for key, vals in mapping.items():
        for v in vals:
            if v in targets:
                hit.add(key)
                break
    return hit

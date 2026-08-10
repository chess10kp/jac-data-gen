"""Solve a dependency graph.

    Parameters
    ----------
    dependencies : dict
        For each key, the value is an iterable indicating its dependencies.
    all_members : iterable, optional
        List of all keys in the graph.
        Useful to guarantee that all keys will be in the result even
        if they are disconnected from the graph.
        (Default value: empty)

    Returns
    -------
    list of sets
        Each set contains tasks that depend only on the tasks
        in the previous set in the list.

    """
def solve_dependencies(dependencies: dict[str, list[str]], all_members: list[str] | None = None) -> list[set[str]] {
    d = {key: set(value) for (key, value) in dependencies.items()};
    if all_members {
        d.update({
            key: set()
            for key in all_members
            if key not in d
        });
    }
    r = [];
    while d {
        t = set(i for v in d.values() for i in v) - set(d.keys());
        t.update(
            k
            for (k, v) in d.items()
            if not v
        );
        r.append(t);
        d = {
            k: (v - t)
            for (k, v) in d.items()
            if v
        };
    }
    return r;
}
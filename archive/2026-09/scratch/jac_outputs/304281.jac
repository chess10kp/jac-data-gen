"""Get all leafs of a DAG."""
def leafage(elts: list[int], fun_deps: Callable[[int], list[int]]) -> set[int] {
    done = set();
    todo = set(elts);
    leafs = set();
    while todo {
        e = todo.pop();
        done.add(e);
        deps = fun_deps(e);
        if len(deps) == 0 {
            leafs.add(e);
        } else {
            for d in deps {
                if d not in done {
                    todo.add(d);
                }
            }
        }
    }
    return leafs;
}
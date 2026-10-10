# Hidden tests: CPython Lib/test/test_graphlib.py (v3.12.7) ported to Jac.
import from topo_sort { TopologicalSorter, CycleError }

def groups_of(ts: TopologicalSorter) -> list[list[int]] {
    out: list[list[int]] = [];
    ts.prepare();
    while ts.is_active() {
        nodes = ts.get_ready();
        for n in nodes {
            ts.done(n);
        }
        out.append(sorted(list(nodes)));
    }
    return out;
}

def check_graph(deps: dict[int, list[int]], expected: list[list[int]]) -> bool {
    if groups_of(TopologicalSorter(deps=deps)) != expected {
        return False;
    }
    order = list(TopologicalSorter(deps=deps).static_order());
    i = 0;
    for grp in expected {
        if set(order[i:i + len(grp)]) != set(grp) {
            return False;
        }
        i += len(grp);
    }
    return i == len(order);
}

def cycle_found(deps: dict[int, list[int]], cycle: list[int]) -> bool {
    ts = TopologicalSorter();
    for (n, pre) in deps.items() {
        ts.add(n, *pre);
    }
    try {
        ts.prepare();
    } except CycleError as e {
        seq = list(e.args[1]);
        assert seq[0] == seq[-1];
        return " ".join([str(x) for x in cycle]) in " ".join([str(x) for x in seq + seq]);
    }
    return False;
}

def raises_value_error(f: any, needle: str) -> bool {
    try {
        f();
    } except ValueError as e {
        return needle in str(e);
    }
    return False;
}

test "simple cases" {
    assert check_graph({2: [11], 9: [11, 8], 10: [11, 3], 11: [7, 5], 8: [7, 3]}, [[3, 5, 7], [8, 11], [2, 9, 10]]);
    assert check_graph({1: []}, [[1]]);
    assert check_graph({x: [x + 1] for x in range(10)}, [[x] for x in range(10, -1, -1)]);
    assert check_graph({2: [3], 3: [4], 4: [5], 5: [1], 11: [12], 12: [13], 13: [14], 14: [15]},
                       [[1, 15], [5, 14], [4, 13], [3, 12], [2, 11]]);
    assert check_graph({0: [1, 2], 1: [3], 2: [5, 6], 3: [4], 4: [9], 5: [3], 6: [7], 7: [8], 8: [4], 9: []},
                       [[9], [4], [3, 8], [1, 5, 7], [6], [2], [0]]);
    assert check_graph({0: [1, 2], 1: [], 2: [3], 3: []}, [[1, 3], [2], [0]]);
    assert check_graph({0: [1, 2], 1: [], 2: [3], 3: [], 4: [5], 5: [6], 6: []}, [[1, 3, 6], [2, 5], [0, 4]]);
}

test "no dependencies" {
    assert check_graph({1: [2], 3: [4], 5: [6]}, [[2, 4, 6], [1, 3, 5]]);
    assert check_graph({1: [], 3: [], 5: []}, [[1, 3, 5]]);
}

test "same node multiple times" {
    assert check_graph({1: [2], 3: [4], 0: [2, 4, 4, 4, 4, 4]}, [[2, 4], [0, 1, 3]]);
    ts = TopologicalSorter();
    ts.add(1, 2);
    ts.add(1, 2);
    ts.add(1, 2);
    assert list(ts.static_order()) == [2, 1];
}

test "incremental adds equal dict construction" {
    ts = TopologicalSorter();
    for p in [2, 3, 4, 5] {
        ts.add(1, p);
    }
    ts2 = TopologicalSorter(deps={1: [2, 3, 4, 5]});
    assert list(ts.static_order()) == list(ts2.static_order());
    ts3 = TopologicalSorter(deps={0: [1, 3, 5, 7, 9]});
    assert list(ts3.static_order()) == [1, 3, 5, 7, 9, 0];
}

test "empty graph" {
    assert len(list(TopologicalSorter().static_order())) == 0;
    assert check_graph({}, []);
}

test "cycles" {
    assert cycle_found({1: [1]}, [1, 1]);
    assert cycle_found({1: [2], 2: [1]}, [1, 2, 1]);
    assert cycle_found({1: [2], 2: [3], 3: [1]}, [1, 3, 2, 1]);
    assert cycle_found({1: [2], 2: [3], 3: [1], 5: [4], 4: [6]}, [1, 3, 2, 1]);
    assert cycle_found({1: [2], 2: [1], 3: [4], 4: [5], 6: [7], 7: [6]}, [1, 2, 1]);
    assert cycle_found({1: [2], 2: [3], 3: [2, 4], 4: [5]}, [3, 2]);
    assert isinstance(CycleError("x", []), ValueError);
}

test "partial progress after a cycle" {
    ts = TopologicalSorter(deps={1: [2], 2: [1], 3: [4]});
    raised = False;
    try {
        ts.prepare();
    } except CycleError {
        raised = True;
    }
    assert raised;
    assert list(ts.get_ready()) == [4];
    ts.done(4);
    assert list(ts.get_ready()) == [3];
}

test "calls before prepare" {
    ts = TopologicalSorter();
    assert raises_value_error(lambda -> any { return ts.get_ready(); }, "prepare() must be called first");
    assert raises_value_error(lambda -> any { ts.done(3); }, "prepare() must be called first");
    assert raises_value_error(lambda -> any { return ts.is_active(); }, "prepare() must be called first");
}

test "prepare twice and add after prepare" {
    ts = TopologicalSorter();
    ts.prepare();
    assert raises_value_error(lambda -> any { ts.prepare(); }, "cannot prepare() more than once");
    assert raises_value_error(lambda -> any { ts.add(1, 2); }, "Nodes cannot be added after a call to prepare()");
}

test "invalid nodes in done" {
    ts = TopologicalSorter();
    ts.add(1, 2, 3, 4);
    ts.add(2, 3, 4);
    ts.prepare();
    ts.get_ready();
    assert raises_value_error(lambda -> any { ts.done(2); }, "node 2 was not passed out");
    assert raises_value_error(lambda -> any { ts.done(24); }, "node 24 was not added using add()");
    ts.done(3);
    assert raises_value_error(lambda -> any { ts.done(3); }, "node 3 was already marked done");
}

test "done unblocks successors" {
    ts = TopologicalSorter();
    ts.add(1, 2, 3, 4);
    ts.add(2, 3);
    ts.prepare();
    assert list(ts.get_ready()) == [3, 4];
    assert len(ts.get_ready()) == 0;
    ts.done(3);
    assert list(ts.get_ready()) == [2];
    assert len(ts.get_ready()) == 0;
    ts.done(4);
    ts.done(2);
    assert list(ts.get_ready()) == [1];
    assert len(ts.get_ready()) == 0;
    ts.done(1);
    assert len(ts.get_ready()) == 0;
    assert not ts.is_active();
}

test "is_active and truthiness" {
    ts = TopologicalSorter();
    ts.add(1, 2);
    ts.prepare();
    assert ts.is_active();
    assert bool(ts);
    assert list(ts.get_ready()) == [2];
    assert ts.is_active();
    ts.done(2);
    assert ts.is_active();
    assert list(ts.get_ready()) == [1];
    assert ts.is_active();
    ts.done(1);
    assert not ts.is_active();
    assert not bool(ts);
}

test "insertion order does not matter between groups" {
    def groups(ts: TopologicalSorter) -> list[set[int]] {
        out: list[set[int]] = [];
        ts.prepare();
        while ts.is_active() {
            nodes = ts.get_ready();
            ts.done(*nodes);
            out.append(set(nodes));
        }
        return out;
    }
    ts = TopologicalSorter();
    ts.add(3, 2, 1);
    ts.add(1, 0);
    ts.add(4, 5);
    ts.add(6, 7);
    ts.add(4, 7);
    ts2 = TopologicalSorter();
    ts2.add(1, 0);
    ts2.add(3, 2, 1);
    ts2.add(4, 7);
    ts2.add(6, 7);
    ts2.add(4, 5);
    assert groups(ts) == groups(ts2);
}

test "string nodes keep insertion order" {
    ts = TopologicalSorter();
    ts.add("blech", "bluch", "hola");
    ts.add("abcd", "blech", "bluch", "a", "b");
    ts.add("a", "a string", "something", "b");
    ts.add("bluch", "hola", "abcde", "a", "b");
    assert list(ts.static_order()) == ["hola", "b", "a string", "something", "abcde", "a", "bluch", "blech", "abcd"];
}

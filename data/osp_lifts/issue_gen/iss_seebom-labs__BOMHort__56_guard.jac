"""Guard: BOMHort#56 candidate + hidden semantics tests."""

import from iss_seebom-labs__BOMHort__56 {
    Component,
    Depends,
    DependencyService,
    ClosureWalker,
    CycleWalker,
    TreeRowsWalker,
}

test "direct deps sorted" {
    svc = DependencyService();
    root_c = svc.add_component("root", "app");
    a = svc.add_component("a", "lib-a");
    b = svc.add_component("b", "lib-b");
    svc.link_dependency(root_c, a);
    svc.link_dependency(root_c, b);
    assert svc.direct_dependencies("root") == ["a", "b"];
}

test "closure diamond adversarial order" {
  # b->d before a->c->d so revisit fires before deeper first-visits on alternate path
    svc = DependencyService();
    root_c = svc.add_component("root", "app");
    a = svc.add_component("a", "lib-a");
    b = svc.add_component("b", "lib-b");
    c = svc.add_component("c", "lib-c");
    d = svc.add_component("d", "shared-d");
    svc.link_dependency(root_c, "a");
    svc.link_dependency(root_c, "b");
    svc.link_dependency(b, d);
    svc.link_dependency(a, c);
    svc.link_dependency(c, d);
    assert svc.dependency_closure("root") == ["a", "b", "c", "d", "root"];
}

test "cycle detection" {
    svc = DependencyService();
    x = svc.add_component("x", "x");
    y = svc.add_component("y", "y");
    z = svc.add_component("z", "z");
    svc.link_dependency(x, y);
    svc.link_dependency(y, z);
    svc.link_dependency(z, x);
    assert svc.has_cycle() is True;
}

test "tree rows depth order" {
    svc = DependencyService();
    root_c = svc.add_component("root", "app");
    a = svc.add_component("a", "lib-a");
    b = svc.add_component("b", "lib-b");
    c = svc.add_component("c", "lib-c");
    d = svc.add_component("d", "shared-d");
    svc.link_dependency(root_c, a);
    svc.link_dependency(root_c, b);
    svc.link_dependency(a, c);
    svc.link_dependency(b, d);
    svc.link_dependency(c, d);
    rows = svc.tree_rows("root");
    assert [(depth, id) for (depth, id, _) in rows] == [
        (0, "root"),
        (1, "a"),
        (2, "c"),
        (3, "d"),
        (1, "b"),
    ];
}

test "unknown id raises KeyError" {
    svc = DependencyService();
    try {
        svc.direct_dependencies("missing");
        assert False, "expected KeyError";
    } except KeyError {
        assert True;
    }
}

test "remove outside walk" {
    svc = DependencyService();
    root_c = svc.add_component("root", "app");
    a = svc.add_component("a", "lib-a");
    b = svc.add_component("b", "lib-b");
    svc.link_dependency(root_c, a);
    svc.link_dependency(root_c, b);
    svc.remove_component("a");
    assert svc.direct_dependencies("root") == ["b"];
    assert "a" not in svc.dependency_closure("root");
}

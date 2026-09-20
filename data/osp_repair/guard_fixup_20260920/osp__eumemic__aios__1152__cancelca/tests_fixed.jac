test "cancel cascade revokes active branch but spares fulfilled" {
    tree = new_task_tree();
    root_t = spawn_task(tree);
    a = spawn_task(tree, root_t);
    b = spawn_task(tree, a);
    c = spawn_task(tree, a);
    d = spawn_task(tree, b);
    assert complete(tree, c) == FULFILLED;
    assert cancel(tree, root_t) == 4;
    c_node = _find_task(tree, c);
    assert c_node is not None;
    assert c_node.state == FULFILLED;
    d_node = _find_task(tree, d);
    assert d_node is not None;
    assert d_node.state == REVOKED;
    assert active_descendants(tree, root_t) == [];
}

test "cancel mid-branch and sweep detached leaves" {
    tree = new_task_tree();
    r2 = spawn_task(tree);
    x = spawn_task(tree, r2);
    y = spawn_task(tree, x);
    z = spawn_task(tree, y);
    w = spawn_task(tree, x);
    assert complete(tree, z) == FULFILLED;
    assert cancel(tree, x) == 3;
    assert active_children(tree, x) == [];
    assert active_descendants(tree, y) == [];
    removed = sweep(tree);
    assert removed >= 1;
    while removed > 0 {
        removed = sweep(tree);
    }
    raised = False;
    try {
        cancel(tree, "ghost");
    } except KeyError {
        raised = True;
    }
    assert raised;
    cancel(tree, r2);
    for t in [tree -->][?:Task] {
        assert t.state != ACTIVE;
    }
}
import from main { ChainOfCommand, Employee, ReportsTo }
test "typed hierarchy preserves directed links" {
    ceo = Employee(title="CEO", level=5);
    vp_eng = Employee(title="VP-Eng", level=4);
    vp_sales = Employee(title="VP-Sales", level=4);
    root +>:ReportsTo(since="2018"):+> ceo;
    ceo +>:ReportsTo(since="2019"):+> vp_eng;
    ceo +>:ReportsTo(since="2019"):+> vp_sales;
    assert len([root-->]) == 1, f"got {len([root-->])}";
    assert len([ceo-->]) == 2, f"got {len([ceo-->])}";
    linked = [ceo ->:ReportsTo:->];
    assert vp_eng in linked, f"got {len(linked)}";
    assert vp_sales in linked, f"got {len(linked)}";
    assert vp_eng.level == 4, f"got {vp_eng.level}";
}

test "recursive walk follows hierarchy and honors depth cap" {
    ceo = Employee(title="CEO", level=5);
    vp = Employee(title="VP", level=4);
    mgr = Employee(title="Manager", level=3);
    leaf = Employee(title="Leaf", level=2);
    root +>:ReportsTo(since="2018"):+> ceo;
    ceo +>:ReportsTo(since="2019"):+> vp;
    vp +>:ReportsTo(since="2020"):+> mgr;
    mgr +>:ReportsTo(since="2021"):+> leaf;
    res = root spawn ChainOfCommand(max_depth=10);
    assert "up[0]: CEO" in res.visits, f"got {res.visits}";
    assert "up[2]: VP" in res.visits, f"got {res.visits}";
    assert "up[6]: Manager" in res.visits, f"got {res.visits}";
    assert "up[14]: Leaf" in res.visits, f"got {res.visits}";
    assert "  (depth cap reached — anchor exhausted)" in res.visits, f"got {res.visits}";
    assert "  (depth cap reached — recursive member exhausted)" in res.visits, f"got {res.visits}";
}

test "leaf anchor terminates when no recursive edge exists" {
    leaf = Employee(title="Leaf", level=1);
    res = leaf spawn ChainOfCommand(max_depth=4);
    assert len(res.visits) == 2, f"got {res.visits}";
    assert res.visits[0] == "up[0]: Leaf", f"got {res.visits}";
    assert res.visits[1] == "  (top of chain — anchor terminated)", f"got {res.visits}";
}

test "report describes portable recursive CTE" {
    anchor = Employee(title="Anchor", level=1);
    root +>:ReportsTo(since="2024"):+> anchor;
    cte_runner = ChainOfCommand();
    sql = cte_runner.report();
    assert "WITH RECURSIVE" in sql, f"got {sql}";
    assert "UNION ALL" in sql, f"got {sql}";
    assert "SELECT title, level FROM employees WHERE id = :leaf_id" in sql, f"got {sql}";
    assert "JOIN chain c ON e.id = c.manager_id" in sql, f"got {sql}";
    assert "SQLite 3.8.3+" in sql, f"got {sql}";
    assert "MySQL 8.0+" in sql, f"got {sql}";
    assert "PostgreSQL 11+" in sql, f"got {sql}";
}

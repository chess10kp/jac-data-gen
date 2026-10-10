import from toollib { Tool, Member, Lent, Receipt, RegisterTool, Checkout, Return, OverdueReport }

def setup_tools() {
    root spawn RegisterTool(code="DR1", name="Drill");
    root spawn RegisterTool(code="SW1", name="Saw");
    root spawn RegisterTool(code="LD1", name="Ladder");
}

test "checkout creates a loan with due day" {
    setup_tools();
    r = root spawn Checkout(card="c1", code="DR1", day=10);
    assert len(r.reports) == 1;
    assert r.reports[0].ok == True;
    assert r.reports[0].due_day == 17;
    r2 = root spawn Checkout(card="c2", code="SW1", day=3, loan_days=2);
    assert r2.reports[0].due_day == 5;
    m = [root -->[?:Member, card == "c1"]];
    assert len(m) == 1;
    assert len([m[0] ->:Lent:->]) == 1;
}

test "unknown tool is refused and creates nothing" {
    setup_tools();
    r = root spawn Checkout(card="c1", code="NOPE", day=1);
    assert r.reports[0].ok == False;
    assert r.reports[0].reason == "unknown tool";
}

test "already lent tool is refused" {
    setup_tools();
    root spawn Checkout(card="c1", code="DR1", day=1);
    r = root spawn Checkout(card="c2", code="DR1", day=2);
    assert r.reports[0].ok == False;
    assert r.reports[0].reason == "already lent";
    r2 = root spawn Checkout(card="c1", code="DR1", day=2);
    assert r2.reports[0].reason == "already lent";
}

test "member limit of two tools" {
    setup_tools();
    assert (root spawn Checkout(card="c1", code="DR1", day=1)).reports[0].ok;
    assert (root spawn Checkout(card="c1", code="SW1", day=1)).reports[0].ok;
    r = root spawn Checkout(card="c1", code="LD1", day=1);
    assert r.reports[0].ok == False;
    assert r.reports[0].reason == "limit reached";
    assert (root spawn Checkout(card="c2", code="LD1", day=1)).reports[0].ok;
}

test "same card maps to one member node" {
    setup_tools();
    root spawn Checkout(card="c1", code="DR1", day=1);
    root spawn Checkout(card="c1", code="SW1", day=1);
    assert len([root -->[?:Member]]) == 1;
}

test "return frees the tool for someone else" {
    setup_tools();
    root spawn Checkout(card="c1", code="DR1", day=1);
    r = root spawn Return(code="DR1");
    assert r.reports[0].ok == True;
    assert len([root -->[?:Tool, code == "DR1"]]) == 1;
    assert len([root -->[?:Member, card == "c1"]]) == 1;
    again = root spawn Checkout(card="c2", code="DR1", day=4);
    assert again.reports[0].ok == True;
}

test "return also frees a member slot" {
    setup_tools();
    root spawn Checkout(card="c1", code="DR1", day=1);
    root spawn Checkout(card="c1", code="SW1", day=1);
    root spawn Return(code="SW1");
    r = root spawn Checkout(card="c1", code="LD1", day=1);
    assert r.reports[0].ok == True;
}

test "return of a tool not on loan" {
    setup_tools();
    r = root spawn Return(code="LD1");
    assert r.reports[0].ok == False;
    assert r.reports[0].reason == "not lent";
    r2 = root spawn Return(code="GHOST");
    assert r2.reports[0].reason == "not lent";
    root spawn Checkout(card="c1", code="LD1", day=1);
    root spawn Return(code="LD1");
    r3 = root spawn Return(code="LD1");
    assert r3.reports[0].ok == False;
}

test "overdue is strict, ordered by due day then code" {
    setup_tools();
    root spawn RegisterTool(code="AX1", name="Axe");
    root spawn Checkout(card="zed", code="SW1", day=0, loan_days=5);
    root spawn Checkout(card="amy", code="DR1", day=0, loan_days=3);
    root spawn Checkout(card="amy", code="AX1", day=0, loan_days=5);
    root spawn Checkout(card="bob", code="LD1", day=0, loan_days=9);
    w = root spawn OverdueReport(today=9);
    assert len(w.reports) == 1;
    assert w.reports[0] == ["amy:DR1", "amy:AX1", "zed:SW1"];
    w2 = root spawn OverdueReport(today=3);
    assert len(w2.reports[0]) == 0;
}

test "returned loans are not overdue" {
    setup_tools();
    root spawn Checkout(card="c1", code="DR1", day=0, loan_days=1);
    root spawn Return(code="DR1");
    w = root spawn OverdueReport(today=50);
    assert len(w.reports[0]) == 0;
}

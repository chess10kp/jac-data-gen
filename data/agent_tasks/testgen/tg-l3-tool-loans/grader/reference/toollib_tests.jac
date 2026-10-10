import from toollib { Tool, Member, Lent, Receipt, RegisterTool, Checkout, Return, OverdueReport }

def reg(code: str, name: str) -> Receipt {
    return (root spawn RegisterTool(code=code, name=name)).reports[0];
}

def out(card: str, code: str, day: int) -> Receipt {
    return (root spawn Checkout(card=card, code=code, day=day)).reports[0];
}

def back(code: str) -> Receipt {
    return (root spawn Return(code=code)).reports[0];
}

test "registering creates one tool per code and renames on repeat" {
    assert reg("HM1", "Hammer").ok == True;
    reg("HM1", "Claw hammer");
    tools = [root -->[?:Tool]];
    assert len(tools) == 1;
    assert tools[0].name == "Claw hammer";
}

test "default loan is seven days" {
    reg("HM1", "Hammer");
    r = out("c1", "HM1", 20);
    assert r.ok == True;
    assert r.reason == "";
    assert r.due_day == 27;
}

test "custom loan length" {
    reg("HM1", "Hammer");
    w = root spawn Checkout(card="c1", code="HM1", day=4, loan_days=1);
    assert len(w.reports) == 1;
    assert w.reports[0].due_day == 5;
    m = [root -->[?:Member, card == "c1"]][0];
    assert [edge m ->:Lent:->][0].due_day == 5;
}

test "unknown tool is refused without creating a member" {
    r = out("c1", "NONE", 1);
    assert r.ok == False;
    assert r.reason == "unknown tool";
    assert len([root -->[?:Member]]) == 0;
}

test "tool already out is refused for anyone" {
    reg("HM1", "Hammer");
    out("c1", "HM1", 1);
    r = out("c2", "HM1", 2);
    assert r.ok == False;
    assert r.reason == "already lent";
    assert out("c1", "HM1", 2).reason == "already lent";
}

test "two tools per member" {
    reg("A", "a");
    reg("B", "b");
    reg("C", "c");
    assert out("m", "A", 1).ok == True;
    assert out("m", "B", 1).ok == True;
    r = out("m", "C", 1);
    assert r.ok == False;
    assert r.reason == "limit reached";
    assert out("n", "C", 1).ok == True;
    assert len([root -->[?:Member]]) == 2;
}

test "member node is reused across checkouts" {
    reg("A", "a");
    reg("B", "b");
    out("m", "A", 1);
    out("m", "B", 1);
    m = [root -->[?:Member]];
    assert len(m) == 1;
    assert len([m[0] ->:Lent:->]) == 2;
}

test "return makes the tool available again" {
    reg("A", "a");
    out("m", "A", 1);
    r = back("A");
    assert r.ok == True;
    assert len([root -->[?:Tool]]) == 1;
    assert len([root -->[?:Member]]) == 1;
    assert out("n", "A", 2).ok == True;
}

test "return frees a slot for the member" {
    reg("A", "a");
    reg("B", "b");
    reg("C", "c");
    out("m", "A", 1);
    out("m", "B", 1);
    back("A");
    assert out("m", "C", 1).ok == True;
}

test "returning something not on loan fails" {
    reg("A", "a");
    r = back("A");
    assert r.ok == False;
    assert r.reason == "not lent";
    assert back("ZZZ").reason == "not lent";
    out("m", "A", 1);
    assert back("A").ok == True;
    assert back("A").ok == False;
}

test "overdue only after the due day" {
    reg("A", "a");
    out("m", "A", 0);
    assert len((root spawn OverdueReport(today=7)).reports[0]) == 0;
    assert (root spawn OverdueReport(today=8)).reports[0] == ["m:A"];
}

test "overdue is sorted by due day then tool code" {
    reg("Z1", "z");
    reg("B1", "b");
    reg("K1", "k");
    reg("Q1", "q");
    root spawn Checkout(card="ann", code="Z1", day=0, loan_days=2);
    root spawn Checkout(card="bob", code="B1", day=0, loan_days=4);
    root spawn Checkout(card="ann", code="K1", day=0, loan_days=2);
    root spawn Checkout(card="cat", code="Q1", day=0, loan_days=30);
    w = root spawn OverdueReport(today=10);
    assert len(w.reports) == 1;
    assert w.reports[0] == ["ann:K1", "ann:Z1", "bob:B1"];
}

test "returned tools drop off the overdue report" {
    reg("A", "a");
    out("m", "A", 0);
    back("A");
    assert len((root spawn OverdueReport(today=99)).reports[0]) == 0;
}

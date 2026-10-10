import from orgchart { Employee, Manages, Headcount, PayrollTotal, ChainOfCommand }

def org -> dict[str, Employee] {
    o: dict[str, Employee] = {};
    o["boss"] = Employee(name="Rhea", title="CEO", salary=500);
    o["cto"] = Employee(name="Sol", title="CTO", salary=300);
    o["cfo"] = Employee(name="Tia", title="CFO", salary=280);
    o["dev1"] = Employee(name="Uma", title="Dev", salary=150);
    o["dev2"] = Employee(name="Vic", title="Dev", salary=140);
    o["intern"] = Employee(name="Wes", title="Intern", salary=20);
    o["acct"] = Employee(name="Xia", title="Accountant", salary=110);
    o["boss"] +>:Manages:+> o["cto"];
    o["boss"] +>:Manages:+> o["cfo"];
    o["cto"] +>:Manages:+> o["dev1"];
    o["cto"] +>:Manages:+> o["dev2"];
    o["dev2"] +>:Manages:+> o["intern"];
    o["cfo"] +>:Manages:+> o["acct"];
    return o;
}

test "headcount excludes the manager themself" {
    o = org();
    w = o["boss"] spawn Headcount();
    assert len(w.reports) == 1;
    assert w.reports[0] == 6;
    assert (o["cto"] spawn Headcount()).reports[0] == 3;
    assert (o["cfo"] spawn Headcount()).reports[0] == 1;
}

test "headcount of an individual contributor is zero" {
    o = org();
    assert (o["intern"] spawn Headcount()).reports[0] == 0;
    assert (Employee(name="Solo") spawn Headcount()).reports[0] == 0;
}

test "payroll includes the manager and everyone below" {
    o = org();
    w = o["boss"] spawn PayrollTotal();
    assert len(w.reports) == 1;
    assert w.reports[0] == 1500;
    assert (o["cto"] spawn PayrollTotal()).reports[0] == 610;
    assert (o["dev2"] spawn PayrollTotal()).reports[0] == 160;
    assert (o["acct"] spawn PayrollTotal()).reports[0] == 110;
}

test "payroll of default employee is zero" {
    assert (Employee(name="New") spawn PayrollTotal()).reports[0] == 0;
}

test "chain of command goes upward nearest first" {
    o = org();
    w = o["intern"] spawn ChainOfCommand();
    assert len(w.reports) == 1;
    assert list(w.reports[0]) == ["Vic", "Sol", "Rhea"];
    assert list((o["acct"] spawn ChainOfCommand()).reports[0]) == ["Tia", "Rhea"];
}

test "the top of the tree has no chain" {
    o = org();
    assert len((o["boss"] spawn ChainOfCommand()).reports[0]) == 0;
}

test "walkers do not change the org" {
    o = org();
    o["boss"] spawn PayrollTotal();
    o["intern"] spawn ChainOfCommand();
    assert len([o["boss"] ->:Manages:->]) == 2;
    assert o["dev1"].salary == 150;
}

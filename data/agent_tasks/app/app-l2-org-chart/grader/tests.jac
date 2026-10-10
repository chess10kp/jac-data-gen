import from orgchart { Employee, Manages, Headcount, PayrollTotal, ChainOfCommand }

def build -> dict[str, Employee] {
    ceo = Employee(name="Ada", title="CEO", salary=300);
    vp1 = Employee(name="Grace", title="VP Eng", salary=200);
    vp2 = Employee(name="Barbara", title="VP Ops", salary=190);
    e1 = Employee(name="Linus", title="Engineer", salary=120);
    e2 = Employee(name="Ken", title="Engineer", salary=110);
    lead = Employee(name="Margaret", title="Ops Lead", salary=130);
    e3 = Employee(name="Dennis", title="Analyst", salary=90);
    ceo +>:Manages:+> vp1;
    ceo +>:Manages:+> vp2;
    vp1 +>:Manages:+> e1;
    vp1 +>:Manages:+> e2;
    vp2 +>:Manages:+> lead;
    lead +>:Manages:+> e3;
    return {"ceo": ceo, "vp1": vp1, "vp2": vp2, "e1": e1, "lead": lead, "e3": e3};
}

test "headcount counts everyone below" {
    g = build();
    assert (g["ceo"] spawn Headcount()).reports[0] == 6;
    assert (g["vp1"] spawn Headcount()).reports[0] == 2;
    assert (g["vp2"] spawn Headcount()).reports[0] == 2;
    assert (g["e3"] spawn Headcount()).reports[0] == 0;
}

test "payroll includes self and subtree" {
    g = build();
    assert (g["ceo"] spawn PayrollTotal()).reports[0] == 1140;
    assert (g["vp2"] spawn PayrollTotal()).reports[0] == 410;
    assert (g["e1"] spawn PayrollTotal()).reports[0] == 120;
}

test "chain of command nearest first" {
    g = build();
    assert (g["e3"] spawn ChainOfCommand()).reports[0] == ["Margaret", "Barbara", "Ada"];
    assert (g["e1"] spawn ChainOfCommand()).reports[0] == ["Grace", "Ada"];
    assert len((g["ceo"] spawn ChainOfCommand()).reports[0]) == 0;
}

test "each walker reports once" {
    g = build();
    assert len((g["ceo"] spawn Headcount()).reports) == 1;
    assert len((g["ceo"] spawn PayrollTotal()).reports) == 1;
    assert len((g["e3"] spawn ChainOfCommand()).reports) == 1;
}

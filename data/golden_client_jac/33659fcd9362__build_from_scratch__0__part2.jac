edge OnDay {}
edge Signed {}

node Hub {}

node Day {
    has date: str = "";
}

node Visitor {
    has name: str = "";
}

def count_signatures(hub: Hub) -> int {
    signatures = 0;
    for day in [hub-->[?:Day]] {
        signatures += len([day-->[?:Visitor]]);
    }
    return signatures;
}

with entry {
    hub = Hub();

    d1 = hub +>: OnDay() :+> Day(date="2026-06-01");
    d1[0] +>: Signed() :+> Visitor(name="a");
    d1[0] +>: Signed() :+> Visitor(name="b");

    d2 = hub +>: OnDay() :+> Day(date="2026-06-02");
    d2[0] +>: Signed() :+> Visitor(name="c");
    d2[0] +>: Signed() :+> Visitor(name="d");
    d2[0] +>: Signed() :+> Visitor(name="e");

    d3 = hub +>: OnDay() :+> Day(date="2026-06-03");
    d3[0] +>: Signed() :+> Visitor(name="f");

    print(count_signatures(hub));
}

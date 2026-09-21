"""Corporate budget rollup.

Because exit abilities are deferred until every descendant is finished
(post-order execution), each organisational unit can sum its children's
already-completed subtotals inside its own exit ability. Innermost
units therefore report first and totals bubble up to the top.
"""

node Unit {
    has name: str;
    has own_budget: int;
    has subtotal: int = 0;
}

walker Auditor {
    has company_total: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can descend with Unit entry {
        visit [-->];
    }

    # Runs AFTER all descendant units have exited, so their subtotals
    # are already finalized on the nodes.
    can roll_up with Unit exit {
        child_sum = 0;
        for kid in [-->][?:Unit] {
            child_sum += kid.subtotal;
        }
        here.subtotal = here.own_budget + child_sum;
        print(f"{here.name}: subtotal = {here.subtotal}");
        self.company_total = here.subtotal;
    }
}

with entry {
    hq = Unit(name="HQ", own_budget=100);

    engineering = Unit(name="Engineering", own_budget=200);
    backend = Unit(name="Backend", own_budget=120);
    frontend = Unit(name="Frontend", own_budget=80);

    sales = Unit(name="Sales", own_budget=150);

    root ++> hq;
    hq ++> engineering ++> backend;
    engineering ++> frontend;
    hq ++> sales;

    audit = Auditor();
    root spawn audit;
    print(f"company total = {audit.company_total}");
}

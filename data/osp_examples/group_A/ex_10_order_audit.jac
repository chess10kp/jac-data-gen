"""Order audit: skip leaves the ability, disengage ends the walker.

Invalid orders are skipped (the auditor just returns from the current
ability and keeps going), but the moment a flagged fraudulent order
shows up the entire audit disengages. The printed trail shows which
mechanism fired where.
"""

node Order {
    has order_id: str = "";
    has amount: float = 0.0;
    has valid: bool = True;
    has flagged_fraud: bool = False;
}

walker Auditor {
    has audited: int = 0;

    can start with Root entry {
        print("Audit started");
        visit [-->];
    }

    can check with Order entry {
        # Queue the continuation FIRST: `skip` only leaves this ability,
        # and if nothing else is queued the walker would stop entirely.
        visit [-->];
        if here.flagged_fraud {
            print(f"{here.order_id}: FRAUD FLAG - halting the whole audit");
            disengage;
        }
        if not here.valid {
            print(f"{here.order_id}: invalid, skipping just this order");
            skip;
        }
        self.audited += 1;
        print(f"{here.order_id}: ok (${here.amount:.2f})");
    }
}

with entry {
    root ++> Order(order_id="A-1001", amount=49.99)
        ++> Order(order_id="A-1002", amount=120.00, valid=False)
        ++> Order(order_id="A-1003", amount=15.50)
        ++> Order(order_id="A-1004", amount=999.99, flagged_fraud=True)
        ++> Order(order_id="A-1005", amount=8.25);

    auditor = root spawn Auditor();
    print(f"Orders fully audited before halt: {auditor.audited}");
}

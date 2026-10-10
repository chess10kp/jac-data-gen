import from toollib { OverdueReport, Checkout, Return }

with entry {
    w = root spawn OverdueReport(today=20);
    print("OVERDUE=" + ",".join(w.reports[0]));
    r = root spawn Checkout(card="M2", code="T1", day=20);
    print("SECOND=" + r.reports[0].reason);
    back = root spawn Return(code="T1");
    print("RETURNED=" + str(back.reports[0].ok));
}

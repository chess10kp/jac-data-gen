import from toollib { RegisterTool, Checkout }

with entry {
    root spawn RegisterTool(code="T1", name="Drill");
    root spawn RegisterTool(code="T2", name="Saw");
    r = root spawn Checkout(card="M9", code="T1", day=1);
    print("SEED_OK=" + str(r.reports[0].ok));
}

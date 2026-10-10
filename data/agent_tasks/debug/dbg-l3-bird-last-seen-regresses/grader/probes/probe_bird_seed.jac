import from survey { LogSighting }

with entry {
    root spawn LogSighting(site="Pond", species="Grebe", count=3, day=10);
    root spawn LogSighting(site="Pond", species="Teal", count=1, day=10);
    root spawn LogSighting(site="Field", species="Teal", count=2, day=11);
    print("SEED_DONE");
}

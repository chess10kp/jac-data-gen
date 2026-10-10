import from garage { Enter, Leave, Occupancy }

with entry {
    dup = root spawn Enter(plate="KX-1", minute=150);
    print("DUP=" + dup.reports[0].reason);
    fee = root spawn Leave(plate="KX-2", minute=200);
    print("FEE=" + str(fee.reports[0]));
    occ = root spawn Occupancy();
    print("TOTAL=" + str(occ.total));
}

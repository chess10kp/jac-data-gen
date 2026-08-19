node Town { has gain: int; }
edge Road { has toll: int; }

walker TripLedger {
    has bal: int = 0;
    can settle with Town entry {
        self.bal += here.gain;
        for e in [edge here -->] { self.bal -= e.toll; }
        visit [-->];
    }
}

def toll_trip_balance(spec: dict) -> int {
    towns: list = [Town(gain=int(g)) for g in spec["gains"]];
    for (i, fee) in enumerate(spec["tolls"]) {
        towns[i] +>:Road(toll=int(fee)):+> towns[i + 1];
    }
    ledger = towns[0] spawn TripLedger();
    return ledger.bal;
}

with entry {
    print(toll_trip_balance({'gains': [5, 3, 8], 'tolls': [2, 4]}));
}

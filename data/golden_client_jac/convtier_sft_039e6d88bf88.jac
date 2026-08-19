node Station {}
edge Ride { has fare: int; has promo: bool; }

walker FareMeter {
    has total: int = 0;
    can charge with Ride entry {
        if here.promo { self.total += here.fare // 2; }
        else { self.total += here.fare; }
    }
    can advance with Station entry { visit [edge -->]; }
}

def discounted_total(spec: dict) -> int {
    fares: list = list(spec["fares"]);
    stations: list = [Station() for _ in range(len(fares) + 1)];
    for (i, f) in enumerate(fares) {
        stations[i] +>:Ride(fare=int(f), promo=bool(spec["promos"][i])):+> stations[i + 1];
    }
    return (stations[0] spawn FareMeter()).total;
}

with entry {
    print(discounted_total({'fares': [10, 7], 'promos': [True, False]}));
}

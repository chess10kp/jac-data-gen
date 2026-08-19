node Hub {}
node City {}
edge Route { has fare: int; }

walker FareScan {
    has best: int = -1;
    can scan with Hub entry {
        for e in [edge here -->] {
            if self.best == -1 or e.fare < self.best { self.best = e.fare; }
        }
    }
}

def cheapest_spoke(spec: dict) -> int {
    hub = Hub();
    for f in spec["fares"] { hub +>:Route(fare=int(f)):+> City(); }
    return (hub spawn FareScan()).best;
}

with entry {
    print(cheapest_spoke({'fares': [7, 3, 9]}));
}

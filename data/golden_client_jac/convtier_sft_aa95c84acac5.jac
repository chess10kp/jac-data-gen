node Camp {}
edge Trail { has dist: int; }

walker LegScan {
    has best: int = -1;
    can measure with Trail entry {
        if here.dist > self.best { self.best = here.dist; }
    }
    can advance with Camp entry { visit [edge -->]; }
}

def longest_leg(spec: dict) -> int {
    dists: list = list(spec["dists"]);
    camps: list = [Camp() for _ in range(len(dists) + 1)];
    for (i, d) in enumerate(dists) {
        camps[i] +>:Trail(dist=int(d)):+> camps[i + 1];
    }
    return (camps[0] spawn LegScan()).best;
}

with entry {
    print(longest_leg({'dists': [4, 9, 2]}));
}

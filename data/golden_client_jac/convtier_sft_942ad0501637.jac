node Stop {}
edge Road { has toll: int; }

walker TollTally {
    has total: int = 0;
    can pay with Road entry { self.total += here.toll; }
    can advance with Stop entry { visit [edge -->]; }
}

def chain_toll_total(spec: dict) -> int {
    tolls: list = list(spec["tolls"]);
    stops: list = [Stop() for _ in range(len(tolls) + 1)];
    for (i, t) in enumerate(tolls) {
        stops[i] +>:Road(toll=int(t)):+> stops[i + 1];
    }
    return (stops[0] spawn TollTally()).total;
}

with entry {
    print(chain_toll_total({'tolls': [2, 3, 4]}));
}

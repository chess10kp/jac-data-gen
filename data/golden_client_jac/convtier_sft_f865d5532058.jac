node City { has name: str; }
node Shop { has revenue: int; }

walker RevenueSum {
    has total: int = 0;
    can open with City entry { visit [-->][?:Shop]; }
    can add with Shop entry { self.total += here.revenue; }
}

def top_city_revenue(spec: dict) -> str {
    cities: dict = dict(spec["cities"]);
    if len(cities) == 0 { return ""; }
    cnodes: dict = {};
    for (nm, revs) in cities.items() {
        c = City(name=str(nm));
        cnodes[nm] = c;
        for r in list(revs) { c ++> Shop(revenue=int(r)); }
    }
    best: str = ""; bt: int = 0; seen: bool = False;
    for nm in sorted(cnodes.keys()) {
        t: int = (cnodes[nm] spawn RevenueSum()).total;
        if not seen or t > bt { best = nm; bt = t; seen = True; }
    }
    return best;
}

with entry {
    print(top_city_revenue({'cities': {'berlin': [12, 40], 'oslo': [60]}}));
}

node Stop { has km: int; }

walker RouteScan {
    has stops: int = 0;
    has dist: int = 0;
    has line: str = "";
    can ride with Stop entry {
        self.stops += 1;
        self.dist += here.km;
        visit [-->];
    }
    can settle with exit {
        self.line = "stops=" + str(self.stops) + ";km=" + str(self.dist);
    }
}

def route_summary(spec: dict) -> str {
    kms: list = list(spec["kms"]);
    if not kms { return "stops=0;km=0"; }
    stops: list = [Stop(km=int(v)) for v in kms];
    for (a, b) in zip(stops, stops[1:]) { a ++> b; }
    return (stops[0] spawn RouteScan()).line;
}

with entry {
    print(route_summary({'kms': [12, 30]}));
}

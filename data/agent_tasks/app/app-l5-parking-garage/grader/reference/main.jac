"""Parking garage: a Garage node with Stay nodes; open stays are parked cars."""

import math;

node Garage {
    has capacity: int = 0;
}

node Stay {
    has plate: str;
    has entered: str;
    has left: str = "";
    has fee: float = 0.0;
}

def garage -> Garage {
    gs = [g for g in [root -->[?:Garage]]];
    return gs[0] if gs else root ++> Garage();
}

def parked(g: Garage) -> list[Stay] {
    return [s for s in [g -->[?:Stay]] if s.left == ""];
}

def minutes_of(t: str) -> int {
    if len(t) != 5 or t[2] != ":" or not t[:2].isdigit() or not t[3:].isdigit() {
        return -1;
    }
    h = int(t[:2]);
    m = int(t[3:]);
    if h > 23 or m > 59 {
        return -1;
    }
    return h * 60 + m;
}

def fee_for(minutes: int) -> float {
    if minutes <= 30 {
        return 0.0;
    }
    return 2.0 * math.ceil(minutes / 60);
}

def:pub occupancy() -> dict[str, any] {
    g = garage();
    cars = parked(g);
    return {"capacity": g.capacity, "occupied": len(cars), "free": g.capacity - len(cars),
            "plates": sorted([s.plate for s in cars])};
}

def:pub set_capacity(spots: int) -> dict[str, any] {
    g = garage();
    if spots < 1 {
        return {"error": "capacity must be at least 1"};
    }
    if spots < len(parked(g)) {
        return {"error": "more cars parked than spots"};
    }
    g.capacity = spots;
    return occupancy();
}

def:pub park(plate: str, at: str) -> dict[str, any] {
    g = garage();
    p = plate.strip().upper();
    if minutes_of(at) < 0 {
        return {"error": "bad time"};
    }
    cars = parked(g);
    if p in [s.plate for s in cars] {
        return {"error": "already parked"};
    }
    if len(cars) >= g.capacity {
        return {"error": "garage full"};
    }
    g ++> Stay(plate=p, entered=at);
    return {"plate": p, "entered": at};
}

def:pub leave(plate: str, at: str) -> dict[str, any] {
    g = garage();
    p = plate.strip().upper();
    out = minutes_of(at);
    if out < 0 {
        return {"error": "bad time"};
    }
    for s in parked(g) {
        if s.plate == p {
            mins = out - minutes_of(s.entered);
            if mins < 0 {
                return {"error": "leave time before entry"};
            }
            s.left = at;
            s.fee = fee_for(mins);
            return {"plate": p, "minutes": mins, "fee": s.fee};
        }
    }
    return {"error": "not parked"};
}

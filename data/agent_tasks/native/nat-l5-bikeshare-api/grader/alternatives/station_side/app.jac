"""Bike-share dock service.

Graph (per operator account):
    root --> Station -Docked-> Bike
    root --> Rider  -Riding-> Bike
"""

node Station {
    has code: str;
    has capacity: int;
}

node Bike {
    has serial: str;
    has km: float = 0.0;
}

node Rider {
    has name: str;
}

edge Docked: Station --> Bike {}

edge Riding: Rider --> Bike {
    has since: int = 0;
}

def:pub add_station(code: str, capacity: int) -> Station {
    return root ++> Station(code=code, capacity=capacity);
}

def:pub add_bike(station: str, serial: str, km: float) -> bool {
    for s in [root -->[?:Station]] {
        if s.code == station and len([s ->:Docked:->]) < s.capacity {
            s +>:Docked():+> Bike(serial=serial, km=km);
            return True;
        }
    }
    return False;
}


"""Rent: walk to the station; the station hands out its least-worn bike."""
walker:pub rent_bike {
    has station: str;
    has rider: str;
    has minute: int = 0;
    has found: bool = False;

    can locate with Root entry {
        visit [-->[?:Station, code == self.station]];
    }

    can hand_out with Station entry {
        self.found = True;
        riders = [r for r in [root -->[?:Rider]] if r.name == self.rider];
        if riders and [riders[0] ->:Riding:->] {
            report {"ok": False, "reason": "already riding"};
            disengage;
        }
        best: Bike | None = None;
        best_km = 0.0;
        best_serial = "";
        for b in [here ->:Docked:->] {
            if best is None or b.km < best_km or (b.km == best_km and b.serial < best_serial) {
                best = b;
                best_km = b.km;
                best_serial = b.serial;
            }
        }
        if best is None {
            report {"ok": False, "reason": "no bikes"};
            disengage;
        }
        rider = riders[0] if riders else root ++> Rider(name=self.rider);
        chosen = best;
        if chosen is not None {
            for doomed in [edge here ->:Docked:-> chosen] {
                del doomed;
            }
            rider +>:Riding(since=self.minute):+> chosen;
            report {"ok": True, "bike": chosen.serial};
        }
    }

    can missing with Root exit {
        if not self.found {
            report {"ok": False, "reason": "unknown station"};
        }
    }
}

walker:pub return_bike {
    has station: str;
    has rider: str;
    has km: float = 0.0;
    has found: bool = False;

    can locate with Root entry {
        visit [-->[?:Station, code == self.station]];
    }

    can take_back with Station entry {
        self.found = True;
        riders = [r for r in [root -->[?:Rider]] if r.name == self.rider];
        riding = [riders[0] ->:Riding:->] if riders else [];
        if not riding {
            report {"ok": False, "reason": "not riding"};
            disengage;
        }
        if len([here ->:Docked:->]) >= here.capacity {
            report {"ok": False, "reason": "station full"};
            disengage;
        }
        bike = riding[0];
        bike.km = bike.km + self.km;
        for doomed in [edge riders[0] ->:Riding:-> bike] {
            del doomed;
        }
        here +>:Docked():+> bike;
        report {"ok": True, "bike": bike.serial};
    }

    can missing with Root exit {
        if not self.found {
            report {"ok": False, "reason": "unknown station"};
        }
    }
}

walker:pub network_status {
    can start with Root entry {
        stations = sorted([-->[?:Station]], key=lambda (s: Station) { s.code; });
        out: list[dict[str, any]] = [];
        for s in stations {
            docked = len([s -->[?:Bike]]);
            out.append({"code": s.code, "bikes": docked, "free": s.capacity - docked});
        }
        report out;
    }
}

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


def find_station(code: str) -> Station | None {
    for s in [root -->[?:Station]] {
        if s.code == code {
            return s;
        }
    }
    return None;
}

def find_rider(name: str) -> Rider | None {
    for r in [root -->[?:Rider]] {
        if r.name == name {
            return r;
        }
    }
    return None;
}

walker:pub rent_bike {
    has station: str;
    has rider: str;
    has minute: int = 0;

    can rent with Root entry {
        st = find_station(self.station);
        if st is None {
            report {"ok": False, "reason": "unknown station"};
            return;
        }
        rd = find_rider(self.rider);
        if rd is not None and len([rd ->:Riding:->]) > 0 {
            report {"ok": False, "reason": "already riding"};
            return;
        }
        docked = [st ->:Docked:->];
        if not docked {
            report {"ok": False, "reason": "no bikes"};
            return;
        }
        bike = sorted(docked, key=lambda (b: Bike) { (b.km, b.serial); })[0];
        if rd is None {
            rd = root ++> Rider(name=self.rider);
        }
        del [edge st ->:Docked:-> bike];
        rd +>:Riding(since=self.minute):+> bike;
        report {"ok": True, "bike": bike.serial};
    }
}

walker:pub return_bike {
    has station: str;
    has rider: str;
    has km: float = 0.0;

    can give_back with Root entry {
        st = find_station(self.station);
        if st is None {
            report {"ok": False, "reason": "unknown station"};
            return;
        }
        rd = find_rider(self.rider);
        bikes = [rd ->:Riding:->] if rd is not None else [];
        if rd is None or not bikes {
            report {"ok": False, "reason": "not riding"};
            return;
        }
        if len([st ->:Docked:->]) >= st.capacity {
            report {"ok": False, "reason": "station full"};
            return;
        }
        bike = bikes[0];
        bike.km += self.km;
        del [edge rd ->:Riding:-> bike];
        st +>:Docked():+> bike;
        report {"ok": True, "bike": bike.serial};
    }
}

walker:pub network_status {
    has rows: list[dict[str, any]] = [];

    can start with Root entry {
        visit [-->[?:Station]];
    }

    can count with Station entry {
        n = len([here ->:Docked:->]);
        self.rows.append({"code": here.code, "bikes": n, "free": here.capacity - n});
    }

    can finish with Root exit {
        report sorted(self.rows, key=lambda (r: dict[str, any]) { r["code"]; });
    }
}

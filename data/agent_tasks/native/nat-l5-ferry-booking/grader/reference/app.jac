"""Island ferry reservations.

root --> Sailing -Holds-> Booking
"""

enum Vehicle {
    FOOT,
    CAR,
    VAN
}

node Sailing {
    has code: str;
    has day: int;
    has car_slots: int;     # deck lanes; a VAN takes 2, a CAR takes 1
    has foot_slots: int;    # seats for foot passengers
}

node Booking {
    has ref: str;
    has vehicle: Vehicle;
    has passengers: int;

    def car_use -> int {
        if self.vehicle == Vehicle.VAN {
            return 2;
        }
        return 1 if self.vehicle == Vehicle.CAR else 0;
    }

    def foot_use -> int {
        return self.passengers if self.vehicle == Vehicle.FOOT else 0;
    }
}

edge Holds: Sailing --> Booking {}

def:pub add_sailing(code: str, day: int, car_slots: int, foot_slots: int) -> Sailing {
    return root ++> Sailing(code=code, day=day, car_slots=car_slots, foot_slots=foot_slots);
}

"""Look up a Vehicle member by its name (None if there is no such member)."""
def vehicle_named(label: str) -> Vehicle | None {
    for m in Vehicle {
        if m.name == label {
            return m;
        }
    }
    return None;
}

def sailing_named(code: str) -> Sailing | None {
    for s in [root -->[?:Sailing]] {
        if s.code == code {
            return s;
        }
    }
    return None;
}

walker:pub book {
    has sailing: str;
    has ref: str;
    has vehicle: str;
    has passengers: int = 1;

    can make with Root entry {
        s = sailing_named(self.sailing);
        if s is None {
            report {"ok": False, "reason": "unknown sailing"};
            return;
        }
        if [b for b in [root -->[?:Sailing] ->:Holds:->] if b.ref == self.ref] {
            report {"ok": False, "reason": "duplicate ref"};
            return;
        }
        if self.vehicle not in [v.name for v in Vehicle] {
            report {"ok": False, "reason": "bad vehicle"};
            return;
        }
        kind = vehicle_named(self.vehicle) or Vehicle.FOOT;
        new = Booking(ref=self.ref, vehicle=kind, passengers=self.passengers);
        held = [s ->:Holds:->];
        cars = sum([b.car_use() for b in held]) + new.car_use();
        foot = sum([b.foot_use() for b in held]) + new.foot_use();
        if cars > s.car_slots or foot > s.foot_slots {
            report {"ok": False, "reason": "sold out"};
            return;
        }
        s +>:Holds():+> new;
        report {"ok": True, "ref": self.ref};
    }
}

walker:pub cancel {
    has ref: str;
    has done: bool = False;

    can start with Root entry {
        visit [-->[?:Sailing]];
    }

    can look with Sailing entry {
        for b in [here ->:Holds:->] {
            if b.ref == self.ref {
                del b;
                self.done = True;
            }
        }
    }

    can finish with Root exit {
        report {"ok": self.done};
    }
}

walker:pub manifest {
    has sailing: str;

    can show with Root entry {
        s = sailing_named(self.sailing);
        held = [s ->:Holds:->] if s is not None else [];
        report {
            "cars": sum([b.car_use() for b in held]),
            "foot": sum([b.foot_use() for b in held]),
            "refs": sorted([b.ref for b in held])
        };
    }
}

walker:pub day_summary {
    has day: int;
    has rows: list[dict[str, any]] = [];

    can start with Root entry {
        visit [-->[?:Sailing, day == self.day]];
    }

    can tally with Sailing entry {
        held = [here ->:Holds:->];
        self.rows.append({
            "code": here.code,
            "free_car": here.car_slots - sum([b.car_use() for b in held]),
            "free_foot": here.foot_slots - sum([b.foot_use() for b in held])
        });
    }

    can finish with Root exit {
        report sorted(self.rows, key=lambda (r: dict[str, any]) { r["code"]; });
    }
}

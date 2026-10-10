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

    def usage -> tuple[int, int] {
        cars = 0;
        foot = 0;
        for b in [self -->[?:Booking]] {
            match b.vehicle {
                case Vehicle.VAN: cars += 2;
                case Vehicle.CAR: cars += 1;
                case Vehicle.FOOT: foot += b.passengers;
            }
        }
        return (cars, foot);
    }
}

node Booking {
    has ref: str;
    has vehicle: Vehicle;
    has passengers: int;
}

edge Holds: Sailing --> Booking {}

def:pub add_sailing(code: str, day: int, car_slots: int, foot_slots: int) -> Sailing {
    return root ++> Sailing(code=code, day=day, car_slots=car_slots, foot_slots=foot_slots);
}

walker:pub book {
    has sailing: str;
    has ref: str;
    has vehicle: str;
    has passengers: int = 1;
    has handled: bool = False;

    can start with Root entry {
        for b in [-->[?:Sailing] -->[?:Booking]] {
            if b.ref == self.ref {
                if not [s for s in [-->[?:Sailing]] if s.code == self.sailing] {
                    report {"ok": False, "reason": "unknown sailing"};
                } else {
                    report {"ok": False, "reason": "duplicate ref"};
                }
                disengage;
            }
        }
        visit [-->[?:Sailing, code == self.sailing]];
    }

    can place with Sailing entry {
        self.handled = True;
        kinds = {"FOOT": Vehicle.FOOT, "CAR": Vehicle.CAR, "VAN": Vehicle.VAN};
        if self.vehicle not in kinds {
            report {"ok": False, "reason": "bad vehicle"};
            disengage;
        }
        v = kinds[self.vehicle];
        (cars, foot) = here.usage();
        need_car = 2 if v == Vehicle.VAN else (1 if v == Vehicle.CAR else 0);
        need_foot = self.passengers if v == Vehicle.FOOT else 0;
        if cars + need_car > here.car_slots or foot + need_foot > here.foot_slots {
            report {"ok": False, "reason": "sold out"};
            disengage;
        }
        here +>:Holds():+> Booking(ref=self.ref, vehicle=v, passengers=self.passengers);
        report {"ok": True, "ref": self.ref};
    }

    can finish with Root exit {
        if not self.handled {
            report {"ok": False, "reason": "unknown sailing"};
        }
    }
}

walker:pub cancel {
    has ref: str;

    can go with Root entry {
        doomed = [b for b in [-->[?:Sailing] -->[?:Booking]] if b.ref == self.ref];
        for b in doomed {
            del b;
        }
        report {"ok": len(doomed) > 0};
    }
}

walker:pub manifest {
    has sailing: str;
    has out: dict[str, any] = {"cars": 0, "foot": 0, "refs": []};

    can start with Root entry {
        visit [-->[?:Sailing, code == self.sailing]];
    }

    can show with Sailing entry {
        (cars, foot) = here.usage();
        self.out = {"cars": cars, "foot": foot, "refs": sorted([b.ref for b in [here -->[?:Booking]]])};
    }

    can finish with Root exit {
        report self.out;
    }
}

walker:pub day_summary {
    has day: int;

    can go with Root entry {
        rows: list[dict[str, any]] = [];
        for s in sorted([-->[?:Sailing]], key=lambda (x: Sailing) { x.code; }) {
            if s.day == self.day {
                (cars, foot) = s.usage();
                rows.append({"code": s.code, "free_car": s.car_slots - cars, "free_foot": s.foot_slots - foot});
            }
        }
        report rows;
    }
}

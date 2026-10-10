"""Multi-storey car park: Level nodes on root, Level -ParkedOn-> Car."""

node Level {
    has number: int;
    has spots: int;
}

node Car {
    has plate: str;
    has entered_at: int;
}

edge ParkedOn: Level --> Car {}

obj Ticket {
    has ok: bool;
    has level: int = -1;
    has reason: str = "";
}

walker AddLevel {
    has number: int;
    has spots: int;

    can add with Root entry {
        root ++> Level(number=self.number, spots=self.spots);
        report self.number;
    }
}

def find_car(wanted: str) -> Car | None {
    for lvl in [root -->[?:Level]] {
        for car in [lvl ->:ParkedOn:->[?:Car, plate == wanted]] {
            return car;
        }
    }
    return None;
}

walker Enter {
    has plate: str;
    has minute: int;

    can park with Root entry {
        if find_car(self.plate) is not None {
            report Ticket(ok=False, reason="already inside");
            return;
        }
        for lvl in [root -->[?:Level]] {
            if len([lvl ->:ParkedOn:->]) < lvl.spots {
                lvl +>:ParkedOn():+> Car(plate=self.plate, entered_at=self.minute);
                report Ticket(ok=True, level=lvl.number);
                return;
            }
        }
        report Ticket(ok=False, reason="full");
    }
}

walker Leave {
    has plate: str;
    has minute: int;

    can pay with Root entry {
        car = find_car(self.plate);
        if car is None {
            report -1;
            return;
        }
        stay = self.minute - car.entered_at;
        fee = 0;
        if stay > 30 {
            fee = 3 * ((stay + 59) // 60);
        }
        del car;
        report fee;
    }
}

walker Occupancy {
    has total: int = 0;
    has counts: dict[int, int] = {};

    can start with Root entry {
        visit [-->[?:Level]];
    }

    can count with Level entry {
        n = len([here ->:ParkedOn:->]);
        self.counts[here.number] = n;
        self.total = n;
    }

    can finish with Root exit {
        report self.counts;
    }
}

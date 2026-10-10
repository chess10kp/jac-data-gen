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

"""Enter walks the levels in ascending order and parks on the first with room."""
walker Enter {
    has plate: str;
    has minute: int;
    has placed: bool = False;

    can check with Root entry {
        for c in [root -->[?:Level] ->:ParkedOn:->[?:Car]] {
            if c.plate == self.plate {
                report Ticket(ok=False, reason="already inside");
                disengage;
            }
        }
        visit sorted([-->[?:Level]], key=lambda (l: Level) { l.number; });
    }

    can try_level with Level entry {
        if not self.placed and len([here -->[?:Car]]) < here.spots {
            here +>:ParkedOn():+> Car(plate=self.plate, entered_at=self.minute);
            self.placed = True;
            report Ticket(ok=True, level=here.number);
            disengage;
        }
    }

    can finish with Root exit {
        if not self.placed {
            report Ticket(ok=False, reason="full");
        }
    }
}

def parking_fee(stay: int) -> int {
    if stay <= 30 {
        return 0;
    }
    hours = stay // 60;
    if stay % 60 != 0 {
        hours += 1;
    }
    return hours * 3;
}

walker Leave {
    has plate: str;
    has minute: int;
    has fee: int = -1;

    can start with Root entry {
        visit [-->[?:Level]];
    }

    can look with Level entry {
        for c in [here ->:ParkedOn:->] {
            if c.plate == self.plate {
                self.fee = parking_fee(self.minute - c.entered_at);
                del c;
            }
        }
    }

    can finish with Root exit {
        report self.fee;
    }
}

walker Occupancy {
    has total: int = 0;

    can start with Root entry {
        out: dict[int, int] = {};
        for lvl in [-->[?:Level]] {
            out[lvl.number] = len([lvl ->:ParkedOn:->]);
        }
        self.total = sum(out.values());
        report out;
    }
}

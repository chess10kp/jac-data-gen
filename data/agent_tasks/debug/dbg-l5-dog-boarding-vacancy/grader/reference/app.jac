"""Boarding kennel bookings.

root --> Run -Hosts-> Stay
A stay covers nights start .. start + nights - 1.
"""

enum Size {
    SMALL = 1,
    MEDIUM = 2,
    LARGE = 3
}

node Run {
    has code: str;
    has size: Size;
}

node Stay {
    has dog: str;
    has start: int;
    has nights: int;
}

edge Hosts: Run --> Stay {}

def:pub add_run(code: str, size: str) -> Run {
    return root ++> Run(code=code, size=Size[size]);
}

def overlaps(s: Stay, start: int, nights: int) -> bool {
    return s.start < start + nights and start < s.start + s.nights;
}

def run_free(r: Run, start: int, nights: int) -> bool {
    for s in [r ->:Hosts:->] {
        if overlaps(s, start, nights) {
            return False;
        }
    }
    return True;
}

walker:pub book_stay {
    has dog: str;
    has size: str;
    has start: int;
    has nights: int;

    can book with Root entry {
        if self.size not in [s.name for s in Size] {
            report {"ok": False, "reason": "bad size"};
            return;
        }
        if self.nights < 1 {
            report {"ok": False, "reason": "bad dates"};
            return;
        }
        need = Size[self.size].value;
        options = [r for r in [root -->[?:Run]] if r.size.value >= need and run_free(r, self.start, self.nights)];
        if not options {
            report {"ok": False, "reason": "no vacancy"};
            return;
        }
        best = sorted(options, key=lambda (r: Run) { (r.size.value, r.code); })[0];
        best +>:Hosts():+> Stay(dog=self.dog, start=self.start, nights=self.nights);
        report {"ok": True, "run": best.code};
    }
}

walker:pub check_out {
    has dog: str;
    has removed: int = 0;

    can start with Root entry {
        visit [-->[?:Run]];
    }

    can clear with Run entry {
        for s in [here ->:Hosts:->] {
            if s.dog == self.dog {
                del s;
                self.removed += 1;
            }
        }
    }

    can finish with Root exit {
        report self.removed;
    }
}

walker:pub occupancy {
    has night: int;
    has lines: list[str] = [];

    can start with Root entry {
        visit [-->[?:Run]];
    }

    can look with Run entry {
        for s in [here ->:Hosts:->] {
            if overlaps(s, self.night, 1) {
                self.lines.append(f"{here.code}:{s.dog}");
            }
        }
    }

    can finish with Root exit {
        report sorted(self.lines);
    }
}

walker:pub vacancy {
    has start: int;
    has nights: int;
    has free: dict[str, int] = {};

    can begin with Root entry {
        for s in Size {
            self.free[s.name] = 0;
        }
        visit [-->[?:Run]];
    }

    can look with Run entry {
        if run_free(here, self.start, self.nights) {
            self.free[here.size.name] += 1;
        }
    }

    can finish with Root exit {
        report self.free;
    }
}

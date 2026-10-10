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

    """Nights already taken in this run."""
    def taken -> set[int] {
        nights: set[int] = set();
        for s in [self -->[?:Stay]] {
            for n in range(s.start, s.start + s.nights) {
                nights.add(n);
            }
        }
        return nights;
    }

    def free_for(start: int, nights: int) -> bool {
        want = set(range(start, start + nights));
        return len(want & self.taken()) == 0;
    }
}

node Stay {
    has dog: str;
    has start: int;
    has nights: int;
}

edge Hosts: Run --> Stay {}

"""Look up a Size member by its name (None if there is no such member)."""
def size_named(label: str) -> Size | None {
    for m in Size {
        if m.name == label {
            return m;
        }
    }
    return None;
}

def:pub add_run(code: str, size: str) -> Run {
    return root ++> Run(code=code, size=size_named(size) or Size.SMALL);
}

glob ORDER: dict[str, int] = {"SMALL": 1, "MEDIUM": 2, "LARGE": 3};

walker:pub book_stay {
    has dog: str;
    has size: str;
    has start: int;
    has nights: int;

    can book with Root entry {
        if self.size not in ORDER {
            report {"ok": False, "reason": "bad size"};
            disengage;
        }
        if self.nights <= 0 {
            report {"ok": False, "reason": "bad dates"};
            disengage;
        }
        for size_name in ["SMALL", "MEDIUM", "LARGE"] {
            if ORDER[size_name] < ORDER[self.size] {
                continue;
            }
            runs = sorted([r for r in [-->[?:Run]] if r.size.name == size_name], key=lambda (r: Run) { r.code; });
            for r in runs {
                if r.free_for(self.start, self.nights) {
                    r +>:Hosts():+> Stay(dog=self.dog, start=self.start, nights=self.nights);
                    report {"ok": True, "run": r.code};
                    disengage;
                }
            }
        }
        report {"ok": False, "reason": "no vacancy"};
    }
}

walker:pub check_out {
    has dog: str;

    can go with Root entry {
        stays = [s for s in [-->[?:Run] -->[?:Stay]] if s.dog == self.dog];
        n = len(stays);
        for s in stays {
            del s;
        }
        report n;
    }
}

walker:pub occupancy {
    has night: int;

    can go with Root entry {
        out: list[str] = [];
        for r in [-->[?:Run]] {
            for s in [r -->[?:Stay]] {
                if s.start <= self.night and self.night < s.start + s.nights {
                    out.append(r.code + ":" + s.dog);
                }
            }
        }
        report sorted(out);
    }
}

walker:pub vacancy {
    has start: int;
    has nights: int;

    can go with Root entry {
        counts = {"SMALL": 0, "MEDIUM": 0, "LARGE": 0};
        for r in [-->[?:Run]] {
            if r.free_for(self.start, self.nights) {
                counts[r.size.name] = counts[r.size.name] + 1;
            }
        }
        report counts;
    }
}

"""Orienteering course planner: controls worth points, one-way legs between them."""

node Control {
    has code: str;
    has points: int;
}

edge Leg: Control --> Control {
    has metres: int;
}

"""Walk every leg reachable from the spawn control, visiting each control once."""
walker Sweep {
    has seen: list[str] = [];
    has total: int = 0;

    can step with Control entry {
        if here.code in self.seen {
            return;
        }
        self.seen.append(here.code);
        self.total += here.points;
        visit [here ->:Leg:->];
    }
}

node Course {
    has name: str;

    def control(code: str) -> Control | None {
        wanted = code;
        found = [self -->[?:Control, code == wanted]];
        return found[0] if found else None;
    }

    def add_control(code: str, points: int) -> bool {
        if self.control(code) is not None {
            return False;
        }
        self ++> Control(code=code, points=points);
        return True;
    }

    def add_leg(a: str, b: str, metres: int) -> bool {
        src = self.control(a);
        dst = self.control(b);
        if src is None or dst is None {
            return False;
        }
        src +>:Leg(metres=metres):+> dst;
        return True;
    }

    def reachable(start: str) -> list[str] {
        c = self.control(start);
        if c is None {
            return [];
        }
        w = c spawn Sweep();
        return sorted([x for x in w.seen if x != start]);
    }

    def points_from(start: str) -> int {
        c = self.control(start);
        if c is None {
            return 0;
        }
        return (c spawn Sweep()).total;
    }

    def longest_leg_from(code: str) -> int {
        c = self.control(code);
        if c is None {
            return 0;
        }
        return max([0] + [leg.metres for leg in [edge c ->:Leg:->]]);
    }
}

"""Tram network: Stop nodes on root, Track edges (from -> to) tagged by line."""

node Stop {
    has name: str;
}

edge Track: Stop --> Stop {
    has line: str;
    has minutes: int = 2;
}

def stop(label: str) -> Stop {
    found = [root -->[?:Stop, name == label]];
    if found {
        return found[0];
    }
    return root ++> Stop(name=label);
}

def add_hop(line: str, a: str, b: str, minutes: int) {
    stop(a) +>:Track(line=line, minutes=minutes):+> stop(b);
}

walker RunLine {
    has line: str;
    has minutes: int = 0;

    can ride with Stop entry {
        seen: set[str] = set();
        route: list[str] = [];
        cur = here;
        while True {
            seen.add(jid(cur));
            route.append(cur.name);
            hops = [edge cur ->:Track:->];
            matching = [h for h in hops if h.line == self.line];
            if not matching {
                break;
            }
            nxt = [cur ->:Track:line == self.line:->][0];
            if jid(nxt) in seen {
                break;
            }
            self.minutes += matching[0].minutes;
            cur = nxt;
        }
        report route;
    }
}

walker Interchanges {
    has seen_lines: dict[str, set[str]] = {};

    can start with Root entry {
        for s in [-->[?:Stop]] {
            for e in [edge s ->:Track:->] {
                self.seen_lines.setdefault(s.name, set()).add(e.line);
                for t in [s ->:Track:line == e.line:->] {
                    self.seen_lines.setdefault(t.name, set()).add(e.line);
                }
            }
        }
        report sorted([n for (n, ls) in self.seen_lines.items() if len(ls) > 1]);
    }
}

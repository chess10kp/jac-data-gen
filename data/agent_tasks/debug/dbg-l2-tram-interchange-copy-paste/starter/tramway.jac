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

"""Spawn on the first stop of a run: ride one line until it ends or loops."""
walker RunLine {
    has line: str;
    has minutes: int = 0;
    has route: list[str] = [];
    has visited: list[Stop] = [];

    can ride with Stop entry {
        self.visited.append(here);
        self.route.append(here.name);
        for hop in [edge here ->:Track:line == self.line:->] {
            nxt = [here ->:Track:line == self.line:->];
            if nxt and nxt[0] not in self.visited {
                self.minutes += hop.minutes;
                visit nxt[0];
            }
        }
    }

    can done with Stop exit {
        if here == self.visited[0] {
            report self.route;
        }
    }
}

walker Interchanges {
    has hubs: list[str] = [];

    can start with Root entry {
        visit [-->[?:Stop]];
    }

    can check with Stop entry {
        lines: set[str] = set();
        for e in [edge here ->:Track:->] {
            lines.add(e.line);
        }
        for e in [edge here ->:Track:->] {
            lines.add(e.line);
        }
        if len(lines) >= 2 {
            self.hubs.append(here.name);
        }
    }

    can finish with Root exit {
        report sorted(self.hubs);
    }
}

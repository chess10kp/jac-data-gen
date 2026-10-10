"""River catchment model. FlowsInto edges point downstream."""

node Reach {
    has name: str;
    has load_kg: float = 0.0;   # pollutant load entering this reach per day
}

node Station {
    has code: str;
}

edge FlowsInto: Reach --> Reach {
    has seasonal: bool = False;
}

edge Samples: Station --> Reach {}

def connect_reach(up: Reach, down: Reach, seasonal: bool) {
    up +>:FlowsInto(seasonal=seasonal):+> down;
}

def feeders(r: Reach, dry: bool) -> list[Reach] {
    out: list[Reach] = [];
    for src in [r <-:FlowsInto:<-] {
        links = [edge src ->:FlowsInto:-> r];
        usable = [l for l in links if not (dry and l.seasonal)];
        if usable {
            out.append(src);
        }
    }
    return out;
}

"""Same contract, computed eagerly from the station with an explicit frontier."""
walker UpstreamLoad {
    has dry_season: bool = False;
    has total_kg: float = 0.0;

    can run with Station entry {
        found: list[Reach] = [];
        frontier: list[Reach] = list([here ->:Samples:->]);
        while frontier {
            r = frontier.pop();
            if r in found {
                continue;
            }
            found.append(r);
            frontier.extend(feeders(r, self.dry_season));
        }
        self.total_kg = sum([r.load_kg for r in found]);
        report sorted([r.name for r in found]);
    }
}

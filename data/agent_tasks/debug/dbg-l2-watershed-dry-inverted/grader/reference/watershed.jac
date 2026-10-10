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

"""Spawn on a Station: sum the load of the sampled reach and everything upstream of it."""
walker UpstreamLoad {
    has dry_season: bool = False;
    has total_kg: float = 0.0;
    has seen: set[str] = set();
    has names: list[str] = [];

    can begin with Station entry {
        visit [here ->:Samples:->];
    }

    can collect with Reach entry {
        key = jid(here);
        if key in self.seen {
            return;
        }
        self.seen.add(key);
        self.names.append(here.name);
        self.total_kg += here.load_kg;
        if self.dry_season {
            visit [here <-:FlowsInto:seasonal == False:<-];
        } else {
            visit [here <-:FlowsInto:<-];
        }
    }


    can finish with Station exit {
        report sorted(self.names);
    }
}

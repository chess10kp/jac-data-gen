"""Catchment load survey over river-reach records.

reaches: [{"name": str, "load": float}]  daily pollutant load entering each reach (kg)
flows:   [{"from": str, "to": str, "seasonal": bool}]  water flows from -> to (downstream)
Flows that mention an unknown reach are ignored.
"""

import math;

node Reach {
    has name: str;
    has load_kg: float;
}

edge FlowsInto: Reach --> Reach {
    has seasonal: bool = False;
}

"""Spawned on the gauge reach: climbs against the current, each reach once."""
walker Upstream {
    has dry_season: bool = False;
    has names: list[str] = [];
    has loads: list[float] = [];

    can climb with Reach entry {
        if here.name in self.names {
            return;
        }
        self.names.append(here.name);
        self.loads.append(here.load_kg);
        if self.dry_season {
            visit [here <-:FlowsInto:seasonal == False:<-];
        } else {
            visit [here <-:FlowsInto:<-];
        }
    }
}

"""Build a throwaway reach graph from the records; returns reaches by name."""
def build(reaches: list[dict[str, any]], flows: list[dict[str, any]]) -> dict[str, Reach] {
    by_name: dict[str, Reach] = {};
    for r in reaches {
        n = str(r["name"]);
        by_name[n] = Reach(name=n, load_kg=float(r["load"]));
    }
    for f in flows {
        src = str(f["from"]);
        dst = str(f["to"]);
        if src in by_name and dst in by_name {
            by_name[src] +>:FlowsInto(seasonal=bool(f["seasonal"])):+> by_name[dst];
        }
    }
    return by_name;
}

def survey(reaches: list[dict[str, any]], flows: list[dict[str, any]], gauge: str, dry_season: bool) -> Upstream | None {
    graph = build(reaches, flows);
    if gauge not in graph {
        return None;
    }
    return graph[gauge] spawn Upstream(dry_season=dry_season);
}

def upstream_reaches(reaches: list[dict[str, any]], flows: list[dict[str, any]], gauge: str, dry_season: bool) -> list[str] {
    w = survey(reaches, flows, gauge, dry_season);
    return sorted(w.names) if w is not None else [];
}

def upstream_load(reaches: list[dict[str, any]], flows: list[dict[str, any]], gauge: str, dry_season: bool) -> float {
    w = survey(reaches, flows, gauge, dry_season);
    return math.fsum(w.loads) if w is not None else 0.0;
}

def headwaters(reaches: list[dict[str, any]], flows: list[dict[str, any]]) -> list[str] {
    graph = build(reaches, flows);
    return sorted([n for n in graph if not [graph[n] <-:FlowsInto:<-]]);
}

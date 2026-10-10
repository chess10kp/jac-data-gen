"""Catchment load survey over river-reach records.

reaches: [{"name": str, "load": float}]  daily pollutant load entering each reach (kg)
flows:   [{"from": str, "to": str, "seasonal": bool}]  water flows from -> to (downstream)
Flows that mention an unknown reach are ignored.
"""

import math;

def _known(reaches: list[dict[str, any]]) -> dict[str, float] {
    loads: dict[str, float] = {};
    for r in reaches {
        loads[str(r["name"])] = float(r["load"]);
    }
    return loads;
}

def _feeders(reaches: list[dict[str, any]], flows: list[dict[str, any]], dry_season: bool) -> dict[str, list[str]] {
    loads = _known(reaches);
    feeders: dict[str, list[str]] = {};
    for f in flows {
        src = str(f["from"]);
        dst = str(f["to"]);
        if src not in loads or dst not in loads {
            continue;
        }
        if dry_season and bool(f["seasonal"]) {
            continue;
        }
        if dst not in feeders {
            feeders[dst] = [];
        }
        feeders[dst].append(src);
    }
    return feeders;
}

def upstream_reaches(reaches: list[dict[str, any]], flows: list[dict[str, any]], gauge: str, dry_season: bool) -> list[str] {
    if gauge not in _known(reaches) {
        return [];
    }
    feeders = _feeders(reaches, flows, dry_season);
    seen: list[str] = [gauge];
    stack: list[str] = [gauge];
    while len(stack) > 0 {
        cur = stack.pop();
        for up in feeders.get(cur, []) {
            if up not in seen {
                seen.append(up);
                stack.append(up);
            }
        }
    }
    return sorted(seen);
}

def upstream_load(reaches: list[dict[str, any]], flows: list[dict[str, any]], gauge: str, dry_season: bool) -> float {
    loads = _known(reaches);
    return math.fsum([loads[n] for n in upstream_reaches(reaches, flows, gauge, dry_season)]);
}

def headwaters(reaches: list[dict[str, any]], flows: list[dict[str, any]]) -> list[str] {
    feeders = _feeders(reaches, flows, False);
    return sorted([n for n in _known(reaches) if n not in feeders]);
}

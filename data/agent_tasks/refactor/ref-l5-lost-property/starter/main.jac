"""Lost-property office for a tram network.

Each station logs what it finds and numbers its own tags (<station>-1,
<station>-2, ...). Items can be claimed, moved to another station, or disposed
of once they have been held too long unclaimed.
"""

node Office {
    has items: list[dict[str, any]] = [];
    has issued: dict[str, int] = {};
}

def _office() -> Office {
    for n in [root -->] {
        if isinstance(n, Office) {
            return n;
        }
    }
    o = Office();
    root ++> o;
    return o;
}

def _find(o: Office, tag: str) -> dict[str, any] | None {
    for it in o.items {
        if it["tag"] == tag {
            return it;
        }
    }
    return None;
}

def log_item(category: str, color: str, day: int, station: str) -> str {
    o = _office();
    if category not in ["bag", "phone", "umbrella", "keys", "other"] {
        return "";
    }
    n = o.issued.get(station, 0) + 1;
    o.issued[station] = n;
    tag = station + "-" + str(n);
    o.items.append({"tag": tag, "category": category, "color": color, "day": day,
                    "station": station, "claimed_by": "", "claimed_on": -1});
    return tag;
}

def search(category: str, color: str, since_day: int) -> list[str] {
    o = _office();
    hits: list[dict[str, any]] = [];
    for it in o.items {
        if it["claimed_by"] != "" {
            continue;
        }
        if it["category"] == category and it["color"].lower() == color.lower() and it["day"] >= since_day {
            hits.append(it);
        }
    }
    hits = sorted(hits, key=lambda (i: dict[str, any]) { (-i["day"], i["tag"]); });
    return [i["tag"] for i in hits];
}

def claim(tag: str, name: str, day: int) -> str {
    o = _office();
    it = _find(o, tag);
    if it is None {
        return "unknown item";
    }
    if it["claimed_by"] != "" {
        return "already claimed";
    }
    it["claimed_by"] = name;
    it["claimed_on"] = day;
    return "ok";
}

def claims_of(name: str) -> list[str] {
    o = _office();
    out: list[str] = [];
    for it in o.items {
        if it["claimed_by"] == name {
            out.append(it["tag"] + "@" + str(it["claimed_on"]));
        }
    }
    return sorted(out);
}

def transfer(src: str, dst: str) -> int {
    o = _office();
    moved = 0;
    for it in o.items {
        if it["station"] == src and it["claimed_by"] == "" {
            it["station"] = dst;
            moved += 1;
        }
    }
    return moved;
}

def held_at(station: str) -> list[str] {
    o = _office();
    out: list[str] = [];
    for it in o.items {
        if it["station"] == station and it["claimed_by"] == "" {
            out.append(it["tag"]);
        }
    }
    return sorted(out);
}

def expire(today: int, keep_days: int) -> list[str] {
    o = _office();
    gone: list[str] = [];
    keep: list[dict[str, any]] = [];
    for it in o.items {
        if it["claimed_by"] == "" and today - it["day"] > keep_days {
            gone.append(it["tag"]);
        } else {
            keep.append(it);
        }
    }
    o.items = keep;
    return sorted(gone);
}

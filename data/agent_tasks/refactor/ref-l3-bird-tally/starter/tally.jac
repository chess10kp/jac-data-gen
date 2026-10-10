"""Bird survey tallies: per-site species counts, keeping the latest day each was seen."""

node SurveyBook {
    has sites: dict[str, dict[str, dict[str, int]]] = {};
}

def _book() -> SurveyBook {
    for n in [root -->] {
        if isinstance(n, SurveyBook) {
            return n;
        }
    }
    b = SurveyBook();
    root ++> b;
    return b;
}

def log_sighting(site: str, species: str, count: int, day: int) -> bool {
    if count <= 0 {
        return False;
    }
    b = _book();
    if site not in b.sites {
        b.sites[site] = {};
    }
    tally = b.sites[site];
    if species in tally {
        tally[species]["total"] += count;
        if day > tally[species]["last_day"] {
            tally[species]["last_day"] = day;
        }
    } else {
        tally[species] = {"total": count, "last_day": day};
    }
    return True;
}

def site_total(site: str) -> int {
    b = _book();
    if site not in b.sites {
        return 0;
    }
    total = 0;
    for sp in b.sites[site] {
        total += b.sites[site][sp]["total"];
    }
    return total;
}

def site_ranking(site: str) -> list[str] {
    b = _book();
    if site not in b.sites {
        return [];
    }
    rows: list[list[any]] = [];
    for sp in b.sites[site] {
        rows.append([-b.sites[site][sp]["total"], sp]);
    }
    rows.sort();
    out: list[str] = [];
    for r in rows {
        out.append(r[1]);
    }
    return out;
}

def sites_for(species: str) -> list[str] {
    b = _book();
    out: list[str] = [];
    for site in b.sites {
        if species in b.sites[site] {
            out.append(site);
        }
    }
    return sorted(out);
}

def last_seen(species: str) -> int {
    b = _book();
    best = -1;
    for site in b.sites {
        if species in b.sites[site] {
            d = b.sites[site][species]["last_day"];
            if d > best {
                best = d;
            }
        }
    }
    return best;
}

def scarce(max_sites: int) -> list[str] {
    b = _book();
    counts: dict[str, int] = {};
    for site in b.sites {
        for sp in b.sites[site] {
            counts[sp] = counts.get(sp, 0) + 1;
        }
    }
    out: list[str] = [];
    for sp in counts {
        if counts[sp] <= max_sites {
            out.append(sp);
        }
    }
    return sorted(out);
}

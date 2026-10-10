"""Bird survey tallies: per-site species counts, keeping the latest day each was seen."""

node Site {
    has name: str;
}

node Species {
    has name: str;
}

edge Sighted: Site --> Species {
    has total: int = 0;
    has last_day: int = 0;
}

"""Sweep every site from root and collect where one species was sighted."""
walker Census {
    has species: str;
    has sites: list[str] = [];
    has last: int = -1;

    can start with Root entry {
        visit [-->[?:Site]];
    }

    can check with Site entry {
        for sp in [here ->:Sighted:->[?:Species, name == self.species]] {
            link = [edge here ->:Sighted:-> sp][0];
            self.sites.append(here.name);
            self.last = max(self.last, link.last_day);
        }
    }
}

def find_site(label: str) -> Site | None {
    found = [root -->[?:Site, name == label]];
    return found[0] if found else None;
}

def find_species(label: str) -> Species | None {
    found = [root -->[?:Species, name == label]];
    return found[0] if found else None;
}

def log_sighting(site: str, species: str, count: int, day: int) -> bool {
    if count <= 0 {
        return False;
    }
    s = find_site(site);
    if s is None {
        s = root ++> Site(name=site);
    }
    sp = find_species(species);
    if sp is None {
        sp = root ++> Species(name=species);
    }
    links = [edge s ->:Sighted:-> sp];
    if links {
        links[0].total += count;
        links[0].last_day = max(links[0].last_day, day);
    } else {
        s +>:Sighted(total=count, last_day=day):+> sp;
    }
    return True;
}

def _rows(s: Site) -> list[tuple[int, str]] {
    return [([edge s ->:Sighted:-> sp][0].total, sp.name) for sp in [s ->:Sighted:->]];
}

def site_total(site: str) -> int {
    s = find_site(site);
    if s is None {
        return 0;
    }
    return sum([t for (t, n) in _rows(s)]);
}

def site_ranking(site: str) -> list[str] {
    s = find_site(site);
    if s is None {
        return [];
    }
    return [n for (neg, n) in sorted([(-t, n) for (t, n) in _rows(s)])];
}

def sites_for(species: str) -> list[str] {
    return sorted((root spawn Census(species=species)).sites);
}

def last_seen(species: str) -> int {
    return (root spawn Census(species=species)).last;
}

def scarce(max_sites: int) -> list[str] {
    return sorted([sp.name for sp in [root -->[?:Species]] if len([sp <-:Sighted:<-]) <= max_sites]);
}

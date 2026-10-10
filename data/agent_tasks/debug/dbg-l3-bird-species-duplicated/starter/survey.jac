"""Bird survey tallies: Site and Species nodes on root, Site -Sighted-> Species."""

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

def site_named(label: str) -> Site {
    found = [root -->[?:Site, name == label]];
    return found[0] if found else root ++> Site(name=label);
}

def species_named(label: str) -> Species {
    found = [root -->[?:Species, name == label]];
    return found[0] if found else Species(name=label);
}

walker LogSighting {
    has site: str;
    has species: str;
    has count: int;
    has day: int;

    can log with Root entry {
        if self.count <= 0 {
            report False;
            return;
        }
        s = site_named(self.site);
        sp = species_named(self.species);
        links = [edge s ->:Sighted:-> sp];
        if links {
            link = links[0];
            link.total += self.count;
            link.last_day = max(link.last_day, self.day);
        } else {
            s +>:Sighted(total=self.count, last_day=self.day):+> sp;
        }
        report True;
    }
}

walker SiteList {
    has site: str;
    has rows: list[tuple[int, str]] = [];

    can start with Root entry {
        visit [-->[?:Site, name == self.site]];
    }

    can read with Site entry {
        for sp in [here ->:Sighted:->] {
            link = [edge here ->:Sighted:-> sp][0];
            self.rows.append((-link.total, sp.name));
        }
    }

    can finish with Root exit {
        report [name for (neg, name) in sorted(self.rows)];
    }
}

walker Scarce {
    has max_sites: int;
    has names: list[str] = [];

    can start with Root entry {
        visit [-->[?:Species]];
    }

    can judge with Species entry {
        if len([here <-:Sighted:<-]) <= self.max_sites {
            self.names.append(here.name);
        }
    }

    can finish with Root exit {
        report sorted(self.names);
    }
}

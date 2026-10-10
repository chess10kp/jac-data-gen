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

walker LogSighting {
    has site: str;
    has species: str;
    has count: int;
    has day: int;

    can log with Root entry {
        if self.count < 1 {
            report False;
            disengage;
        }
        visit [-->[?:Site, name == self.site]] else {
            visit here ++> Site(name=self.site);
        }
    }

    can record with Site entry {
        sp: Species | None = None;
        for cand in [root -->[?:Species]] {
            if cand.name == self.species {
                sp = cand;
            }
        }
        if sp is None {
            sp = root ++> Species(name=self.species);
        }
        bird = sp;
        if bird is not None {
            updated = False;
            for link in [edge here ->:Sighted:->] {
                if link in [edge here ->:Sighted:-> bird] {
                    link.total = link.total + self.count;
                    if self.day > link.last_day {
                        link.last_day = self.day;
                    }
                    updated = True;
                }
            }
            if not updated {
                here +>:Sighted(total=self.count, last_day=self.day):+> bird;
            }
        }
        report True;
    }
}

walker SiteList {
    has site: str;

    can start with Root entry {
        out: list[str] = [];
        for s in [-->[?:Site, name == self.site]] {
            tallies: dict[str, int] = {};
            for sp in [s ->:Sighted:->] {
                tallies[sp.name] = sum([e.total for e in [edge s ->:Sighted:-> sp]]);
            }
            out = sorted(tallies.keys(), key=lambda (n: str) { (-tallies[n], n); });
        }
        report out;
    }
}

walker Scarce {
    has max_sites: int;

    can start with Root entry {
        seen_at: dict[str, set[str]] = {};
        for s in [-->[?:Site]] {
            for sp in [s ->:Sighted:->] {
                seen_at.setdefault(sp.name, set()).add(s.name);
            }
        }
        report sorted([n for (n, sites) in seen_at.items() if len(sites) <= self.max_sites]);
    }
}

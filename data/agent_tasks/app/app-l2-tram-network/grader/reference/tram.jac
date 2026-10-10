"""Tram network: shortest travel times by walker relaxation over Track edges."""

node Stop {
    has name: str;
}

edge Track: Stop --> Stop {
    has minutes: int = 1;
}

walker TravelTimes {
    """Label-correcting walk: revisit a stop only when a cheaper arrival is found."""
    has best: dict[str, int] = {};

    can relax with Stop entry {
        if here.name not in self.best {
            self.best[here.name] = 0;
        }
        here_cost = self.best[here.name];
        for nxt in [here ->:Track:->] {
            for t in [edge here ->:Track:-> nxt] {
                cost = here_cost + t.minutes;
                if nxt.name not in self.best or cost < self.best[nxt.name] {
                    self.best[nxt.name] = cost;
                    visit nxt;
                }
            }
        }
    }
}

walker FastestTime(TravelTimes) {
    has target: str = "";

    can finish with exit {
        report self.best.get(self.target, -1);
    }
}

walker ReachableWithin(TravelTimes) {
    has budget: int = 0;
    has origin: str = "";

    can mark with Stop entry {
        if self.origin == "" {
            self.origin = here.name;
        }
    }

    can finish with exit {
        report sorted([n for (n, c) in self.best.items() if c <= self.budget and n != self.origin]);
    }
}

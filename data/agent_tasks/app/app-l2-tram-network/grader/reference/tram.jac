"""Tram network: shortest travel times by walker relaxation over Track edges."""

# Anchor this module on the server (Python) backend with an import that has no
# native-stdlib twin (`sys`/`math`/`uuid` do not anchor). Without it jac 0.37.25
# places the module native, demotes the ability that reads edge objects (edge-object
# references are not lowerable) and the mixed native/Python module aborts (SIGABRT).
import heapq;

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
    has target: str;

    can finish with exit {
        report self.best.get(self.target, -1);
    }
}

walker ReachableWithin(TravelTimes) {
    has budget: int;
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

"""Breaker load analysis."""
import from panel { Breaker, Outlet, Appliance, Feeds, PluggedInto }

walker PanelLoad {
    has volts: float = 120.0;
    has loads: dict[str, float] = {};
    has overloaded: list[str] = [];

    can start with Root entry {
        visit [-->[?:Breaker]];
    }

    can measure with Breaker entry {
        watts = 0;
        for o in [here ->:Feeds:->] {
            for a in [o <-:PluggedInto:<-] {
                if a.on {
                    watts += a.watts;
                }
            }
        }
        amps = round(watts / 120.0, 2);
        self.loads[here.label] = amps;
        if amps >= 0.8 * here.amps {
            self.overloaded.append(here.label);
        }
    }

    can finish with Root exit {
        report sorted(self.overloaded);
    }
}

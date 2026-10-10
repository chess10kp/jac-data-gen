"""Inventory reports over the panel graph."""
import from panel { Breaker, Outlet, Appliance, Feeds, PluggedInto }

"""List every plugged-in appliance as "breaker/room: name", sorted."""
walker ListAppliances {
    has lines: list[str] = [];

    can start with Root entry {
        visit [-->[?:Breaker]];
    }

    can on_breaker with Breaker entry {
        for o in [here ->:Feeds:->] {
            for a in [o <-:PluggedInto:<-] {
                self.lines.append(f"{here.label}/{o.room}: {a.name}");
            }
        }
    }

    can finish with Root exit {
        report sorted(self.lines);
    }
}

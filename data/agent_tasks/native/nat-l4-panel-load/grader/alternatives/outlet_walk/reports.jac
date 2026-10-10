"""Inventory reports over the panel graph."""
import from panel { Breaker, Outlet, Appliance, Feeds, PluggedInto }

"""List every plugged-in appliance as "breaker/room: name", sorted."""
walker ListAppliances {
    has lines: list[str] = [];

    can start with Root entry {
        visit [-->[?:Breaker]];
    }

    can on_breaker with Breaker entry {
        visit [here ->:Feeds:->];
    }

    can on_outlet with Outlet entry {
        feeders = [here <-:Feeds:<-];
        label = feeders[0].label if feeders else "?";
        for a in [here <-:PluggedInto:<-] {
            self.lines.append(label + "/" + here.room + ": " + a.name);
        }
    }

    can finish with Root exit {
        report sorted(self.lines);
    }
}

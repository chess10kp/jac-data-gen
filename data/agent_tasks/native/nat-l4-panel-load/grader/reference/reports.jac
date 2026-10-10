"""Inventory reports over the panel graph."""
import from panel { Breaker, Outlet, Appliance, Feeds, PluggedInto }

"""List every plugged-in appliance as "breaker/room: name", sorted."""
walker ListAppliances {
    has lines: list[str] = [];
    has current: str = "";

    can start with Root entry {
        visit [-->[?:Breaker]];
    }

    can on_breaker with Breaker entry {
        self.current = here.label;
        # depth-first: handle this breaker's outlets before the next breaker
        visit :0: [here ->:Feeds:->];
    }

    can on_outlet with Outlet entry {
        for a in [here <-:PluggedInto:<-] {
            self.lines.append(f"{self.current}/{here.room}: {a.name}");
        }
    }

    can finish with Root exit {
        report sorted(self.lines);
    }
}

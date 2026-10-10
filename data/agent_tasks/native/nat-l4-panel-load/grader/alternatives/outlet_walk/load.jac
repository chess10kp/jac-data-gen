import from panel { Breaker, Outlet, Appliance }

"""Outlet-level walk: the walker descends to outlets and charges their draw to the feeding breaker."""
walker PanelLoad {
    has volts: float = 120.0;
    has loads: dict[str, float] = {};
    has watts: dict[str, int] = {};
    has ratings: dict[str, int] = {};

    can start with Root entry {
        for b in [-->[?:Breaker]] {
            self.watts[b.label] = 0;
            self.ratings[b.label] = b.amps;
        }
        visit [--> -->[?:Outlet]];
    }

    can draw with Outlet entry {
        b = [here <--[?:Breaker]][0];
        on_now = [a for a in [here <--[?:Appliance]] if a.on];
        self.watts[b.label] += sum([a.watts for a in on_now]);
    }

    can finish with Root exit {
        hot: list[str] = [];
        for (label, w) in self.watts.items() {
            amps = round(w / self.volts, 2);
            self.loads[label] = amps;
            if amps * 10 > self.ratings[label] * 8 {
                hot.append(label);
            }
        }
        hot.sort();
        report hot;
    }
}

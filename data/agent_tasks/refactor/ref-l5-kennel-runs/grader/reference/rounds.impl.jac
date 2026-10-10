impl PickRun.scan {
    visit [-->[?:Run]];
}

impl PickRun.consider {
    if here.rank() < self.need or not here.free_for(self.start, self.nights) {
        return;
    }
    b = self.best;
    if b is None or here.rank() < b.rank() or (here.rank() == b.rank() and here.code < b.code) {
        self.best = here;
    }
}

impl NightList.scan {
    visit [-->[?:Run]];
}

impl NightList.look {
    for s in [here ->:Hosts:->] {
        if s.covers(self.night, 1) {
            self.lines.append(f"{here.code}:{s.dog}");
        }
    }
}

impl Departure.scan {
    visit [-->[?:Run]];
}

impl Departure.clear {
    for s in [here ->:Hosts:->[?:Stay, dog == self.dog]] {
        del s;
        self.removed += 1;
    }
}

impl Billing.scan {
    visit [-->[?:Run]];
}

impl Billing.enter_run {
    visit [here ->:Hosts:->[?:Stay, dog == self.dog]];
}

impl Billing.charge {
    for e in [edge here <-:Hosts:<-] {
        self.total += e.nightly * here.nights;
    }
}

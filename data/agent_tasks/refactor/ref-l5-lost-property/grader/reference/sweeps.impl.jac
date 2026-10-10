impl Search.scan {
    visit [-->[?:Station]];
}

impl Search.enter_station {
    visit [here ->:Holds:->];
}

impl Search.inspect {
    if not here.is_claimed() and here.matches(self.category, self.color, self.since_day) {
        self.hits.append(here);
    }
}

impl Expiry.scan {
    visit [-->[?:Station]];
}

impl Expiry.enter_station {
    visit [here ->:Holds:->];
}

impl Expiry.inspect {
    if not here.is_claimed() and self.today - here.day > self.keep_days {
        self.stale.append(here);
    }
}

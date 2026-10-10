impl LocateBooking.scan {
    visit [-->[?:Sailing]];
}

impl LocateBooking.look {
    hits = [here ->:Holds:->[?:Booking, ref == self.ref]];
    if hits {
        self.found = hits[0];
        self.at = here;
        disengage;
    }
}

impl DayCount.scan {
    visit [-->[?:Sailing, day == self.day]];
}

impl DayCount.tally {
    self.total += sum([b.passengers for b in [here ->:Holds:->]]);
}

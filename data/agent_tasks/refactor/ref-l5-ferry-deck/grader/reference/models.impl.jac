impl vehicle_named(name: str) -> Vehicle | None {
    for v in Vehicle {
        if v.value == name {
            return v;
        }
    }
    return None;
}

impl Booking.lanes_needed -> int {
    if self.vehicle == Vehicle.VAN {
        return 2;
    }
    return 1 if self.vehicle == Vehicle.CAR else 0;
}

impl Booking.seats_needed -> int {
    return self.passengers if self.vehicle == Vehicle.FOOT else 0;
}

impl Sailing.free_lanes -> int {
    return self.lanes - sum([e.lanes for e in [edge self ->:Holds:->]]);
}

impl Sailing.free_seats -> int {
    return self.seats - sum([e.seats for e in [edge self ->:Holds:->]]);
}

impl Sailing.fits(b: Booking) -> bool {
    return b.lanes_needed() <= self.free_lanes() and b.seats_needed() <= self.free_seats();
}

impl Sailing.take(b: Booking) -> None {
    self +>:Holds(lanes=b.lanes_needed(), seats=b.seats_needed()):+> b;
}

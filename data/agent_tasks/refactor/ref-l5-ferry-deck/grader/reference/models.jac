"""Ferry graph model.

root --> Sailing -Holds(lanes, seats)-> Booking
The space a booking takes on its sailing is recorded on the Holds edge.
"""

enum Vehicle {
    FOOT = "foot",
    CAR = "car",
    VAN = "van"
}

node Booking {
    has ref: str;
    has vehicle: Vehicle;
    has passengers: int;

    def lanes_needed -> int;
    def seats_needed -> int;
}

node Sailing {
    has code: str;
    has day: int;
    has lanes: int;
    has seats: int;

    def free_lanes -> int;
    def free_seats -> int;
    def fits(b: Booking) -> bool;
    def take(b: Booking) -> None;
}

edge Holds: Sailing --> Booking {
    has lanes: int;
    has seats: int;
}

def vehicle_named(name: str) -> Vehicle | None;

"""Island ferry reservations.

root --> Sailing -Holds-> Booking
"""

enum Vehicle {
    FOOT,
    CAR,
    VAN
}

node Sailing {
    has code: str;
    has day: int;
    has car_slots: int;     # deck lanes; a VAN takes 2, a CAR takes 1
    has foot_slots: int;    # seats for foot passengers
}

node Booking {
    has ref: str;
    has vehicle: Vehicle;
    has passengers: int;
}

edge Holds: Sailing --> Booking {}

def:pub add_sailing(code: str, day: int, car_slots: int, foot_slots: int) -> Sailing {
    return root ++> Sailing(code=code, day=day, car_slots=car_slots, foot_slots=foot_slots);
}

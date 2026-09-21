"""Metro line operations.

Node abilities filter by WALKER type: stations announce differently
for drivers than for inspectors. Edge abilities are walker-typed too --
Track only tallies distance for Driver entries -- and they wake at all
only because the driver visits edges explicitly via ``visit [edge -->]``;
the inspector's plain node-to-node traversal never wakes them.
"""

node Station {
    has station_name: str;

    # Typed by walker kind: fires only for Driver walkers.
    can announce with Driver entry {
        print(f"[driver] approaching {self.station_name}");
    }

    # Different filter: fires only for Inspector walkers.
    can note with Inspector entry {
        print(f"[inspector] checking signage at {self.station_name}");
    }
}

edge Track {
    has length_km: float;

    can tally with Driver entry {
        visitor.distance_km += self.length_km;
    }
}

walker Driver {
    has line: str;
    has distance_km: float = 0.0;

    can start with Root entry {
        visit [-->];
    }

    # Visiting EDGES lets Track.abilities fire before continuing.
    can drive with Station entry {
        visit [edge -->];
    }
}

walker Inspector {
    has badge: str;

    can start with Root entry {
        visit [-->];
    }

    # Plain node hops cross edges WITHOUT waking their abilities.
    can ride with Station entry {
        visit [-->];
    }
}

with entry {
    central = Station(station_name="Central");
    museum = Station(station_name="Museum");
    riverside = Station(station_name="Riverside");
    root ++> central +>: Track(length_km=2.4) :+> museum
                        +>: Track(length_km=1.7) :+> riverside;

    driver = Driver(line="Circle Line");
    root spawn driver;
    print(f"driver covered {driver.distance_km} km");

    inspector = Inspector(badge="INSP-9");
    root spawn inspector;
}

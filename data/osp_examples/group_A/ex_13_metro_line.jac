"""Metro line: chained construction in a single expression.

The whole line -- platform plus four stations linked by Track edges --
is built with one chained connection statement. A rider walker then
travels the line end to end.
"""

node Station {
    has name: str = "";
}

edge Track {
    has minutes: float = 2.0;
}

walker Rider {
    has stop_number: int = 0;

    can start with Root entry {
        print("Boarding at the platform");
        visit [-->];
    }

    can ride with Station entry {
        self.stop_number += 1;
        print(f"Stop {self.stop_number}: {here.name}");
        visit [-->];
    }
}

with entry {
    platform = Station(name="Central Platform");

    # One expression builds the entire line.
    root ++> platform
        +>: Track(minutes=3.0) :+> Station(name="Harbor View")
        +>: Track(minutes=4.5) :+> Station(name="Old Town")
        +>: Track(minutes=2.5) :+> Station(name="Museum Row")
        +>: Track(minutes=6.0) :+> Station(name="Airport");

    root spawn Rider();
}

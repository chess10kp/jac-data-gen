"""Parking graph model.

root --> Level -Contains-> Spot -Occupied(since)-> Car
Times are minutes since opening. Fees are in cents.
"""

enum SpotKind {
    STANDARD = "standard",
    EV = "ev"
}

node Level {
    has number: int;
    has takings: int = 0;

    def free_spots(kind: SpotKind) -> list[Spot];
}

node Spot {
    has code: str;
    has kind: SpotKind;

    def is_free -> bool;
}

node Car {
    has plate: str;
}

edge Contains: Level --> Spot {}

"""A car sits in a spot since a given minute."""
edge Occupied: Spot --> Car {
    has since: int;
}

def kind_named(name: str) -> SpotKind | None;
def fee_for(minutes: int) -> int;

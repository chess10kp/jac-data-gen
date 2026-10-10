"""Kennel graph model.

root --> Run -Hosts(nightly)-> Stay
A stay covers nights start .. start + nights - 1.
"""

enum Size {
    SMALL = "small",
    MEDIUM = "medium",
    LARGE = "large"
}

node Run {
    has code: str;
    has size: Size;
    has nightly: int;

    def rank -> int;
    def free_for(start: int, nights: int) -> bool;
}

node Stay {
    has dog: str;
    has start: int;
    has nights: int;

    def covers(start: int, nights: int) -> bool;
}

"""The nightly price is locked on the edge when the stay is booked."""
edge Hosts: Run --> Stay {
    has nightly: int;
}

def size_named(name: str) -> Size | None;
def size_rank(s: Size) -> int;

"""Boarding kennel bookings.

root --> Run -Hosts-> Stay
A stay covers nights start .. start + nights - 1.
"""

enum Size {
    SMALL = 1,
    MEDIUM = 2,
    LARGE = 3
}

node Run {
    has code: str;
    has size: Size;
}

node Stay {
    has dog: str;
    has start: int;
    has nights: int;
}

edge Hosts: Run --> Stay {}

def:pub add_run(code: str, size: str) -> Run {
    return root ++> Run(code=code, size=Size[size]);
}

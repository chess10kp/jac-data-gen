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

"""Look up a Size member by its name (None if there is no such member)."""
def size_named(label: str) -> Size | None {
    for m in Size {
        if m.name == label {
            return m;
        }
    }
    return None;
}

def:pub add_run(code: str, size: str) -> Run {
    return root ++> Run(code=code, size=size_named(size) or Size.SMALL);
}

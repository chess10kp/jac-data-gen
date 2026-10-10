"""Warehouse layout: Warehouse -> Aisle(1) -NextAisle-> Aisle(2) -> ...; each Aisle -Holds(level)-> Bin."""

enum BinState {
    OPEN = "open",
    BLOCKED = "blocked"
}

node Aisle {
    has number: int;
}

node Bin {
    has code: str;
    has sku: str;
    has qty: int;
    has state: BinState = BinState.OPEN;
}

edge NextAisle: Aisle --> Aisle {}

"""level = shelf level the bin sits on (lower levels are picked first)."""
edge Holds: Aisle --> Bin {
    has level: int;
}

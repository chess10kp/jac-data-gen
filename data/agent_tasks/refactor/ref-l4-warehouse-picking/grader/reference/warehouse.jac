"""Warehouse picking: numbered aisles walked in order, bins on shelf levels, blocked bins are skipped.

Each Warehouse owns its own aisle chain (see layout.jac). Bodies live in warehouse.impl.jac.
"""
import from layout { BinState, Aisle, Bin, NextAisle, Holds }

"""Walk the aisle chain from aisle 1 until the order is filled; commit=False is a dry run."""
walker PickRun {
    has order: dict[str, int];
    has commit: bool = True;
    has want: dict[str, int] = {};
    has lines: list[str] = [];
    has entered: int = 0;

    can start with Warehouse entry;
    can on_aisle with Aisle entry;
}

"""Find a bin by code anywhere along the aisle chain."""
walker FindBin {
    has code: str;
    has found: Bin | None = None;

    can start with Warehouse entry;
    can on_aisle with Aisle entry;
}

"""Sum the open stock of one sku along the aisle chain."""
walker OnHand {
    has sku: str;
    has total: int = 0;

    can start with Warehouse entry;
    can on_aisle with Aisle entry;
}

node Warehouse {
    has name: str;
    has aisle_count: int = 0;

    def aisle(number: int) -> Aisle | None;
    def add_aisle -> int;
    def stock(aisle: int, code: str, sku: str, qty: int, level: int) -> bool;
    def block_bin(code: str) -> bool;
    def on_hand(sku: str) -> int;
    def pick(order: dict[str, int]) -> list[str];
    def aisles_needed(order: dict[str, int]) -> int;
}

"""Bins of an aisle in pick order: lowest shelf level first, then stocking order."""
def pick_order(a: Aisle) -> list[Bin];

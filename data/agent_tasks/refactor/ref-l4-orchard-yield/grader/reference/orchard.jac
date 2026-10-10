"""Apple orchard: blocks of numbered rows, trees in slots along a row, harvest forecasts per block.

Each Orchard owns its own subgraph: Orchard -> Block -HasRow-> Row -Planted(slot)-> Tree.
Bodies live in orchard.impl.jac.
"""

enum Variety {
    GALA = "gala",
    FUJI = "fuji",
    BRAEBURN = "braeburn",
    HONEYCRISP = "honeycrisp"
}

node Block {
    has name: str;
}

node Row {
    has number: int;
}

node Tree {
    has tag: str;
    has variety: Variety;
    has age: int;
    has sick: bool = False;
}

edge HasRow: Block --> Row {}

edge Planted: Row --> Tree {
    has slot: int;
}

"""Spawned on a Block: expected kg per variety and healthy trees per row."""
walker Harvest {
    has kg: dict[str, float] = {};
    has rows: dict[int, int] = {};

    can on_block with Block entry;
    can on_row with Row entry;
    can on_tree with Tree entry;
}

"""Spawned on an Orchard: every tree gets a year older."""
walker NextSeason {
    can on_orchard with Orchard entry;
    can on_block with Block entry;
    can on_row with Row entry;
    can on_tree with Tree entry;
}

"""Spawned on an Orchard: find a tree by tag anywhere in it."""
walker Locate {
    has tag: str;
    has found: Tree | None = None;

    can on_orchard with Orchard entry;
    can on_block with Block entry;
    can on_row with Row entry;
}

node Orchard {
    has name: str;

    def block(block: str) -> Block | None;
    def add_block(block: str) -> bool;
    def plant(block: str, row: int, slot: int, tag: str, variety: str, age: int) -> bool;
    def tree_at(block: str, row: int, slot: int) -> str;
    def mark_diseased(tag: str) -> bool;
    def next_season;
    def forecast(block: str) -> float;
    def variety_totals(block: str) -> list[str];
    def healthy_rows(block: str) -> list[int];
}

def parse_variety(name: str) -> Variety | None;
def mature_kg(v: Variety) -> float;
def age_factor(age: int) -> float;

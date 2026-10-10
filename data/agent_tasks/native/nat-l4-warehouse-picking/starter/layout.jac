"""Warehouse layout: aisles form a one-way chain starting from root.

root --> Aisle(1) -NextAisle-> Aisle(2) -NextAisle-> ...
each Aisle -Holds-> Bin (bins in shelf order)
"""

node Aisle {
    has number: int;
}

node Bin {
    has code: str;
    has sku: str;
    has qty: int;
}

edge NextAisle: Aisle --> Aisle {}

edge Holds: Aisle --> Bin {}

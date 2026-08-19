node Category { has name: str; }
node Item {}

walker ShelfCount {
    has total: int = 0;
    can fan with Root entry { visit [-->][?:Category]; }
    can descend with Category entry { visit [-->][?:Item]; }
    can tally with Item entry { self.total += 1; }
}

def total_shelf_items(spec: dict) -> int {
    for old in [root -->] { root del --> old; }
    for (cat, items) in spec["categories"].items() {
        shelf = Category(name=str(cat));
        root ++> shelf;
        for it in list(items) { shelf ++> Item(); }
    }
    return (root spawn ShelfCount()).total;
}

with entry {
    print(total_shelf_items({'categories': {'fruit': ['apple', 'pear'], 'veg': ['kale']}}));
}

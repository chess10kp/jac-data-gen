node Category { has name: str; }
node Item {}

walker SizeCensus {
    has pairs: list = [];
    has sizes: dict = {};
    can fan with Root entry { visit [-->][?:Category]; }
    can size with Category entry {
        self.pairs.append((here.name, len([-->][?:Item])));
    }
    can settle with exit {
        self.pairs.sort();
        for (nm, n) in self.pairs { self.sizes[nm] = n; }
    }
}

def category_sizes(spec: dict) -> dict {
    for old in [root -->] { root del --> old; }
    for (cat, items) in spec["categories"].items() {
        shelf = Category(name=str(cat));
        root ++> shelf;
        for it in list(items) { shelf ++> Item(); }
    }
    return (root spawn SizeCensus()).sizes;
}

with entry {
    print(category_sizes({'categories': {'veg': ['kale'], 'fruit': ['apple', 'pear']}}));
}

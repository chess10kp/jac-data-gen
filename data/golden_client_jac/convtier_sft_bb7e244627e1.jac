node Category { has name: str; }

walker NameScan {
    has names: list = [];
    can fan with Root entry { visit [-->][?:Category]; }
    can grab with Category entry { self.names.append(here.name); }
    can order with exit { self.names.sort(); }
}

def category_names(spec: dict) -> list {
    for old in [root -->] { root del --> old; }
    for cat in list(spec["categories"].keys()) { root ++> Category(name=str(cat)); }
    return (root spawn NameScan()).names;
}

with entry {
    print(category_names({'categories': {'veg': ['kale'], 'fruit': ['apple', 'pear']}}));
}

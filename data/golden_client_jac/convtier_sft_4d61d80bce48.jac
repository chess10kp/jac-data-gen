node Category { has name: str; }
node Item {}

walker BusyScan {
    has pairs: list = [];
    has best: str = "";
    can fan with Root entry { visit [-->][?:Category]; }
    can size with Category entry {
        self.pairs.append((here.name, len([-->][?:Item])));
    }
    can pick with exit {
        if self.pairs {
            self.pairs.sort();
            best_n = -1;
            for (nm, n) in self.pairs {
                if n > best_n { self.best = nm; best_n = n; }
            }
        }
    }
}

def busiest_category(spec: dict) -> str {
    cats: dict = dict(spec["categories"]);
    if not cats { return ""; }
    for old in [root -->] { root del --> old; }
    for (cat, items) in cats.items() {
        shelf = Category(name=str(cat));
        root ++> shelf;
        for it in list(items) { shelf ++> Item(); }
    }
    return (root spawn BusyScan()).best;
}

with entry {
    print(busiest_category({'categories': {'fruit': ['apple', 'pear'], 'veg': ['kale']}}));
}

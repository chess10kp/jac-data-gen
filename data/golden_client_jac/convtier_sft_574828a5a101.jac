node Category { has name: str; }
node Sale { has amount: int; }

walker RevenueScan {
    has pairs: list = [];
    has label: str = "none";
    can fan with Root entry { visit [-->][?:Category]; }
    can total with Category entry {
        subtotal = 0;
        for s in [-->][?:Sale] { subtotal += s.amount; }
        self.pairs.append((here.name, subtotal));
    }
    can crown with exit {
        if self.pairs {
            self.pairs.sort();
            best = ""; best_total = -1;
            for (nm, tot) in self.pairs {
                if tot > best_total { best = nm; best_total = tot; }
            }
            self.label = best + "=" + str(best_total);
        }
    }
}

def richest_category(spec: dict) -> str {
    cats: dict = dict(spec["categories"]);
    if not cats { return "none"; }
    for old in [root -->] { root del --> old; }
    for (cat, amounts) in cats.items() {
        booth = Category(name=str(cat));
        root ++> booth;
        for amt in list(amounts) { booth ++> Sale(amount=int(amt)); }
    }
    return (root spawn RevenueScan()).label;
}

with entry {
    print(richest_category({'categories': {'toys': [5, 3], 'books': [10]}}));
}

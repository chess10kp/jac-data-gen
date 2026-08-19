node Category { has name: str; }
node Item {}

walker FanoutAudit {
    has pairs: list = [];
    has report: str = "empty";
    can fan with Root entry { visit [-->][?:Category]; }
    can size with Category entry {
        self.pairs.append((here.name, len([-->][?:Item])));
    }
    can compose with exit {
        if self.pairs {
            self.pairs.sort();
            parts = [];
            total = 0;
            for (nm, n) in self.pairs {
                total += n;
                parts.append(nm + ":" + str(n));
            }
            self.report = ",".join(parts) + "|total=" + str(total);
        }
    }
}

def fanout_report(spec: dict) -> str {
    for old in [root -->] { root del --> old; }
    for (cat, items) in spec["categories"].items() {
        shelf = Category(name=str(cat));
        root ++> shelf;
        for it in list(items) { shelf ++> Item(); }
    }
    return (root spawn FanoutAudit()).report;
}

with entry {
    print(fanout_report({'categories': {'veg': ['kale'], 'fruit': ['apple', 'pear']}}));
}

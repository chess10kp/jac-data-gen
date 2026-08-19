walker Reporter {
    has parts: list = [];
    has total: int = 0;
    has line: str = "";
    can settle with exit {
        self.line = ",".join(self.parts) + "|sum=" + str(self.total);
    }
}

node Item {
    has label: str;
    has amt: int;
    can log with Reporter entry {
        visitor.parts.append(self.label + ":" + str(self.amt));
        visitor.total += self.amt;
        visit [-->];
    }
}

def chain_report(spec: dict) -> str {
    names: list = list(spec["names"]); nums: list = list(spec["nums"]);
    if not names { return "|sum=0"; }
    items: list = [];
    for (nm, v) in zip(names, nums) { items.append(Item(label=str(nm), amt=int(v))); }
    for (a, b) in zip(items, items[1:]) { a ++> b; }
    return (items[0] spawn Reporter()).line;
}

with entry {
    print(chain_report({'names': ['a', 'b'], 'nums': [2, 5]}));
}

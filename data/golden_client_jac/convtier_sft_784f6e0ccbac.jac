node Branch { has sap: int; has drained: bool = False; }

walker SapAudit {
    has total: int = 0;
    has leaf: int = 0;
    has text: str = "";
    can drain with Branch entry {
        if not here.drained {
            here.drained = True;
            self.total += here.sap;
            if len([-->]) == 0 { self.leaf += here.sap; }
            visit [-->];
        }
    }
    can settle with exit {
        self.text = str(round(100.0 * self.leaf / self.total, 1)) + "%";
    }
}

def leaf_share_percent(spec: dict) -> str {
    adj: dict = dict(spec["adj"]); vals: dict = dict(spec["vals"]);
    grove: dict = {};
    for nm in vals.keys() { grove[nm] = Branch(sap=int(vals[nm])); }
    for (a, bs) in adj.items() { for b in bs { grove[a] ++> grove[b]; } }
    return (grove[str(spec["start"])] spawn SapAudit()).text;
}

with entry {
    print(leaf_share_percent({'adj': {'a': ['b', 'c'], 'b': [], 'c': ['d'], 'd': []}, 'vals': {'a': 2, 'b': 3, 'c': 1, 'd': 4}, 'start': 'a'}));
}

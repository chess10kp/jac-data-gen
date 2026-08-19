node Gene { has name: str; has traced: bool = False; }

walker Lineage {
    has forebears: int = 0;
    can climb with Gene entry {
        if here.traced { return; }
        here.traced = True;
        self.forebears += 1;
        visit [<--];
    }
}

def count_ancestors(spec: dict) -> int {
    adj: dict = dict(spec["adj"]);
    folks: dict = {};
    pairs: list = [];
    for (parent, kids) in adj.items() {
        if parent not in folks { folks[parent] = Gene(name=str(parent)); }
        for kid in kids {
            if kid not in folks { folks[kid] = Gene(name=str(kid)); }
            pairs.append([parent, kid]);
        }
    }
    for pr in pairs { folks[pr[0]] ++> folks[pr[1]]; }
    w = folks[spec["target"]] spawn Lineage();
    return w.forebears - 1;
}

with entry {
    print(count_ancestors({'adj': {'a': ['c'], 'b': ['c'], 'c': ['d'], 'd': []}, 'target': 'd'}));
}

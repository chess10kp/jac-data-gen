node Card { has name: str; has label: str; has used: bool = False; }

walker Tally {
    has target: str;
    has hits: int = 0;
    can mark with Card entry {
        if not here.used {
            here.used = True;
            if here.label == self.target { self.hits += 1; }
            visit [-->];
        }
    }
}

def count_label_matches(spec: dict) -> int {
    adj: dict = spec["adj"]; labels: dict = spec["labels"];
    names: list = list(adj.keys());
    for tgts in adj.values() { for t in tgts { if t not in names { names.append(t); } } }
    cards: dict = {};
    for nm in names { cards[nm] = Card(name=nm, label=labels[nm]); }
    for (src, tgts) in adj.items() { for t in tgts { cards[src] ++> cards[t]; } }
    wk = cards[spec["start"]] spawn Tally(target=spec["target"]);
    return wk.hits;
}

with entry {
    print(count_label_matches({'adj': {'a': ['b', 'c'], 'b': [], 'c': ['d'], 'd': []}, 'labels': {'a': 'red', 'b': 'blue', 'c': 'red', 'd': 'red'}, 'start': 'a', 'target': 'red'}));
}

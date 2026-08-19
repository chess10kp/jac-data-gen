node Doc { has name: str; has tag: str; has read: bool = False; }

walker Histo {
    has counts: dict = {};
    can log_tag with Doc entry {
        if not here.read {
            here.read = True;
            if here.tag in self.counts { self.counts[here.tag] += 1; }
            else { self.counts[here.tag] = 1; }
            visit [-->];
        }
    }
}

def label_histogram(spec: dict) -> dict {
    adj: dict = spec["adj"]; labels: dict = spec["labels"];
    all_names: list = list(adj.keys());
    for ends in adj.values() { for e in ends { if e not in all_names { all_names.append(e); } } }
    docs: dict = {};
    for nm in all_names { docs[nm] = Doc(name=nm, tag=labels[nm]); }
    for (src, ends) in adj.items() { for e in ends { docs[src] ++> docs[e]; } }
    wk = docs[spec["start"]] spawn Histo();
    out: dict = {};
    for k in sorted(wk.counts.keys()) { out[k] = wk.counts[k]; }
    return out;
}

with entry {
    print(label_histogram({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': [], 'd': []}, 'labels': {'a': 'red', 'b': 'blue', 'c': 'red', 'd': 'blue'}, 'start': 'a'}));
}

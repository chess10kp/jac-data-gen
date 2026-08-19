node Site { has tag: str; has hit: bool = False; }

walker TagPick {
    has tags: list = [];
    can mark with Site entry {
        if not here.hit {
            here.hit = True;
            self.tags.append(here.tag);
            visit [-->];
        }
    }
}

def sorted_label_csv(spec: dict) -> str {
    sites: dict = {};
    for (origin, outs) in spec["adj"].items() {
        if origin not in sites { sites[origin] = Site(tag=str(origin)); }
        for target in list(outs) {
            if target not in sites { sites[target] = Site(tag=str(target)); }
            sites[origin] ++> sites[target];
        }
    }
    entry_key: str = str(spec["start"]);
    crawler = sites[entry_key] spawn TagPick();
    return ",".join(sorted(crawler.tags));
}

with entry {
    print(sorted_label_csv({'adj': {'m': ['k', 'z'], 'k': [], 'z': ['b'], 'b': []}, 'start': 'm'}));
}

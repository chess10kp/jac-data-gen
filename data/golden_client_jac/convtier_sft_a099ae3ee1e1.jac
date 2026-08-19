node Tag { has name: str; }

walker TagCount {
    has count: int = 0;
    can tally with Root entry {
        self.count = len([-->][?:Tag]);
    }
}

def unique_root_tags(spec: dict) -> int {
    for old in [root -->] { root del --> old; }
    for t in list(spec["tags"]) {
        if str(t) not in [n.name for n in [root -->][?:Tag]] {
            root ++> Tag(name=str(t));
        }
    }
    return (root spawn TagCount()).count;
}

with entry {
    print(unique_root_tags({'tags': ['red', 'blue', 'red']}));
}

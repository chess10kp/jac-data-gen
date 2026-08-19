node Tag { has label: str; has idx: int = -1; }

walker Stamper {
    has pos: int = 0;
    can stamp with Tag entry {
        here.idx = self.pos;
        self.pos += 1;
        visit [-->];
    }
}

walker Joiner {
    has parts: list = [];
    has line: str = "";
    can read with Tag entry {
        self.parts.append(here.label + str(here.idx));
        visit [-->];
    }
    can settle with exit {
        self.line = ",".join(self.parts);
    }
}

def indexed_labels(spec: dict) -> str {
    names: list = list(spec["names"]);
    if not names { return ""; }
    tags: list = [Tag(label=str(nm)) for nm in names];
    for (a, b) in zip(tags, tags[1:]) { a ++> b; }
    stamper = tags[0] spawn Stamper();
    return (tags[0] spawn Joiner()).line;
}

with entry {
    print(indexed_labels({'names': ['a', 'b', 'c']}));
}

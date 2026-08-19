node GNode {
    has name: str;
    has seen: bool = False;
}

edge Link {}

walker Flood {
    has members: list = [];

    can go with GNode entry {
        self.members.append(here.name);
        for nb in [->:Link:->] {
            if not nb.seen {
                nb.seen = True;
                visit nb;
            }
        }
    }
}

with entry {
    a = GNode(name="A");
    b = GNode(name="B");
    c = GNode(name="C");
    d = GNode(name="D");
    e = GNode(name="E");
    f = GNode(name="F");
    nodes = [a, b, c, d, e, f];

    a <+:Link:+> b;
    b <+:Link:+> c;
    a <+:Link:+> c;
    d <+:Link:+> e;

    components = [];
    for n in nodes {
        if not n.seen {
            n.seen = True;
            w = n spawn Flood();
            components.append(sorted(w.members));
        }
    }
    components.sort();
    print(components);
}

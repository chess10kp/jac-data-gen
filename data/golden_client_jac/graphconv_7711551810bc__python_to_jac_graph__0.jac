node Place {
    has name: str;
    has visited: bool = False;
}

edge Road {}

walker BFSPath {
    has goal: str;
    has pred: dict = {};

    can start with Root entry {
        visit [-->];
    }

    can walk with Place entry {
        if here.name == self.goal {
            disengage;
        }
        for nb in [->:Road:->] {
            if not nb.visited {
                nb.visited = True;
                self.pred[nb.name] = here.name;
                visit nb;
            }
        }
    }
}

with entry {
    a = Place(name="A", visited=True);
    b = Place(name="B");
    c = Place(name="C");
    d = Place(name="D");
    e = Place(name="E");

    root ++> a;
    a <+:Road:+> b;
    a <+:Road:+> c;
    b <+:Road:+> d;
    c <+:Road:+> d;
    c <+:Road:+> e;
    d <+:Road:+> e;

    w = root spawn BFSPath(goal="E");

    name = "E";
    path = [];
    while name != "A" {
        path.append(name);
        name = w.pred[name];
    }
    path.append("A");
    path.reverse();
    print(f"{path} ({len(path) - 1} hops)");
}

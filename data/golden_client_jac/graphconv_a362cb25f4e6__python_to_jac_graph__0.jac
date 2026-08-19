node Vertex {
    has name: str;
}

edge Flow {}

walker DegreeWalker {
    has result: list = [];

    can start with Root entry {
        visit [-->];
    }

    can measure with Vertex entry {
        out_deg = len([->:Flow:->]);
        in_deg = len([<-:Flow:<-]);
        self.result.append((here.name, in_deg, out_deg));
    }
}

with entry {
    a = Vertex(name="A");
    b = Vertex(name="B");
    c = Vertex(name="C");
    d = Vertex(name="D");

    root ++> a;
    root ++> b;
    root ++> c;
    root ++> d;

    a +>:Flow:+> b;
    a +>:Flow:+> c;
    b +>:Flow:+> c;
    c +>:Flow:+> d;
    d +>:Flow:+> b;

    w = root spawn DegreeWalker();
    for (name, in_deg, out_deg) in sorted(w.result) {
        print(f"{name}: in={in_deg} out={out_deg}");
    }
}

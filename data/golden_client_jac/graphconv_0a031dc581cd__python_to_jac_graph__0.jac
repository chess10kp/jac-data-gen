node Module {
    has name: str;
}

edge Imports {}

walker FindRoots {
    has roots: list = [];

    can start with Root entry {
        visit [-->];
    }

    can check with Module entry {
        if len([<-:Imports:<-]) == 0 {
            self.roots.append(here.name);
        }
    }
}

with entry {
    a = Module(name="A");
    b = Module(name="B");
    c = Module(name="C");
    d = Module(name="D");
    e = Module(name="E");
    f = Module(name="F");

    root ++> a;
    root ++> b;
    root ++> c;
    root ++> d;
    root ++> e;
    root ++> f;

    a +>:Imports:+> c;
    b +>:Imports:+> c;
    c +>:Imports:+> d;
    b +>:Imports:+> e;
    f +>:Imports:+> e;

    w = root spawn FindRoots();
    print(sorted(w.roots));
}

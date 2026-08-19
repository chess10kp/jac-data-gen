node Course {
    has name: str;
}

edge Prereq {}

walker TopoSort {
    has order: list = [];

    can start with Root entry {
        courses = [-->][?:Course];
        indeg = {};
        succ = {};
        for n in courses {
            indeg[n.name] = len([n <-:Prereq:<-]);
            succ[n.name] = [m.name for m in [n ->:Prereq:->]];
        }
        available = sorted([nm for nm in indeg.keys() if indeg[nm] == 0]);
        while available {
            cur = available.pop(0);
            self.order.append(cur);
            for v in succ[cur] {
                indeg[v] -= 1;
                if indeg[v] == 0 {
                    available.append(v);
                }
            }
            available.sort();
        }
    }
}

with entry {
    a = Course(name="A");
    b = Course(name="B");
    c = Course(name="C");
    d = Course(name="D");
    e = Course(name="E");

    root ++> a;
    root ++> b;
    root ++> c;
    root ++> d;
    root ++> e;

    a +>:Prereq:+> b;
    a +>:Prereq:+> c;
    b +>:Prereq:+> d;
    c +>:Prereq:+> d;
    d +>:Prereq:+> e;

    w = root spawn TopoSort();
    print(w.order);
}

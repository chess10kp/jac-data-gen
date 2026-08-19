node Stage { has name: str; }
edge Prec { has w: int; }

walker CritPath {
    has eft: int = 0;

    can compute with Stage entry {
        best = 0;
        for p in [<-:Prec:<-] {
            link = [edge p ->:Prec:-> here][0];
            sub = p spawn CritPath();
            best = max(best, sub.eft + link.w);
        }
        self.eft = best;
    }
}

with entry {
    st = Stage(name="start"); a = Stage(name="a"); b = Stage(name="b");
    c = Stage(name="c"); d = Stage(name="d");
    st +>:Prec(w=3):+> a;
    st +>:Prec(w=2):+> b;
    a +>:Prec(w=4):+> c;
    b +>:Prec(w=1):+> c;
    b +>:Prec(w=5):+> d;
    c +>:Prec(w=2):+> d;
    stages = [st, a, b, c, d];
    answer = 0;
    for n in stages {
        res = n spawn CritPath();
        answer = max(answer, res.eft);
    }
    print(f"critical path length = {answer}");
}

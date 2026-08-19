node Bead { has w: int; }
edge Sub {}

walker MaxPath {
    has best: int = 0;

    can go with Bead entry {
        kids = [->:Sub:->];
        if not kids {
            self.best = here.w;
        } else {
            m = 0;
            first = True;
            for k in kids {
                sub = k spawn MaxPath();
                if first {
                    m = sub.best;
                    first = False;
                } else {
                    m = max(m, sub.best);
                }
            }
            self.best = here.w + m;
        }
    }
}

with entry {
    r = Bead(w=10); a = Bead(w=5); b = Bead(w=12);
    c = Bead(w=3); d = Bead(w=9); e = Bead(w=4);
    r +>:Sub:+> a; r +>:Sub:+> b;
    a +>:Sub:+> c; a +>:Sub:+> d;
    b +>:Sub:+> e;
    res = r spawn MaxPath();
    print(f"max path sum = {res.best}");
}

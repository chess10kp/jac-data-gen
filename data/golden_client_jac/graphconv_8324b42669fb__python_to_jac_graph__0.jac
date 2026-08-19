node Dot { has tint: int = -1; }
edge Wire {}

walker TwoColor {
    has clash: bool = False;

    can spread with Dot entry {
        nbrs = [->:Wire:->] + [<-:Wire:<-];
        for nb in nbrs {
            if nb.tint == -1 {
                nb.tint = 1 - here.tint;
                visit nb;
            } elif nb.tint == here.tint {
                self.clash = True;
            }
        }
    }
}

with entry {
    p = Dot(); q = Dot(); r = Dot(); s = Dot();
    p +>:Wire:+> q;
    q +>:Wire:+> r;
    r +>:Wire:+> s;
    s +>:Wire:+> p;
    p.tint = 0;
    w = p spawn TwoColor();
    print(f"bipartite = {not w.clash}");
}

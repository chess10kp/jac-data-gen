node Cell { has key: int; }
edge LKid {}
edge RKid {}

walker Balance {
    has height: int = 0;
    has ok: bool = True;

    can measure with Cell entry {
        lh = 0; rh = 0;
        lb = True; rb = True;
        lefts = [->:LKid:->];
        if lefts {
            ls = lefts[0] spawn Balance();
            lh = ls.height; lb = ls.ok;
        }
        rights = [->:RKid:->];
        if rights {
            rs = rights[0] spawn Balance();
            rh = rs.height; rb = rs.ok;
        }
        self.height = 1 + max(lh, rh);
        self.ok = lb and rb and abs(lh - rh) <= 1;
    }
}

with entry {
    c1 = Cell(key=1); c2 = Cell(key=2); c3 = Cell(key=3);
    c4 = Cell(key=4); c5 = Cell(key=5);
    c1 +>:LKid:+> c2;
    c1 +>:RKid:+> c3;
    c2 +>:LKid:+> c4;
    c4 +>:LKid:+> c5;
    res = c1 spawn Balance();
    print(f"balanced = {res.ok}");
}

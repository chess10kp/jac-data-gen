node Spot { has label: int; }
edge Down {}

walker PathCount {
    has paths: int = 0;

    can count with Spot entry {
        kids = [->:Down:->];
        if not kids {
            self.paths = 1;
        } else {
            total = 0;
            for k in kids {
                sub = k spawn PathCount();
                total += sub.paths;
            }
            self.paths = total;
        }
    }
}

with entry {
    s1 = Spot(label=1); s2 = Spot(label=2); s3 = Spot(label=3); s4 = Spot(label=4);
    s5 = Spot(label=5); s6 = Spot(label=6); s7 = Spot(label=7); s8 = Spot(label=8);
    s1 +>:Down:+> s2; s1 +>:Down:+> s3;
    s2 +>:Down:+> s4; s2 +>:Down:+> s5;
    s3 +>:Down:+> s6;
    s6 +>:Down:+> s7; s6 +>:Down:+> s8;
    r = s1 spawn PathCount();
    print(f"root-to-leaf paths = {r.paths}");
}

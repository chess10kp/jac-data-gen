node Knot { has v: int; }
edge LB {}
edge RB {}

walker Serialize {
    has seq: list = [];

    can walk with Knot entry {
        self.seq = [here.v];
        lefts = [->:LB:->];
        if lefts {
            ls = lefts[0] spawn Serialize();
            self.seq += ls.seq;
        } else {
            self.seq += [-1];
        }
        rights = [->:RB:->];
        if rights {
            rs = rights[0] spawn Serialize();
            self.seq += rs.seq;
        } else {
            self.seq += [-1];
        }
    }
}

with entry {
    a1 = Knot(v=1); a2 = Knot(v=2); a3 = Knot(v=3); a4 = Knot(v=4);
    a1 +>:LB:+> a2; a1 +>:RB:+> a3; a2 +>:LB:+> a4;
    b1 = Knot(v=1); b2 = Knot(v=2); b3 = Knot(v=3); b4 = Knot(v=4);
    b1 +>:LB:+> b2; b1 +>:RB:+> b3; b2 +>:LB:+> b4;
    sa = a1 spawn Serialize();
    sb = b1 spawn Serialize();
    print(f"identical = {sa.seq == sb.seq}");
}

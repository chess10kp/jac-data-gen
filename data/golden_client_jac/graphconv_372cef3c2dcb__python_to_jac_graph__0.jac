node Vert { has v: int; }
edge LC {}
edge RC {}

walker Preord {
    has order: list = [];

    can go with Vert entry {
        self.order = [here.v];
        lefts = [->:LC:->];
        if lefts {
            ls = lefts[0] spawn Preord();
            self.order += ls.order;
        }
        rights = [->:RC:->];
        if rights {
            rs = rights[0] spawn Preord();
            self.order += rs.order;
        }
    }
}

with entry {
    n1 = Vert(v=1); n2 = Vert(v=2); n3 = Vert(v=3);
    n4 = Vert(v=4); n5 = Vert(v=5); n6 = Vert(v=6);
    n1 +>:LC:+> n2; n1 +>:RC:+> n5;
    n2 +>:LC:+> n3; n2 +>:RC:+> n4;
    n5 +>:RC:+> n6;
    res = n1 spawn Preord();
    print("flattened: " + " -> ".join([str(x) for x in res.order]));
}

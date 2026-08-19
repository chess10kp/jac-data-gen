node Item {
    has val: int;
    has lvl: int = 0;
}

edge Branch {}

walker LevelOrder {
    has buckets: dict = {};

    can start with Root entry {
        visit [-->];
    }

    can walk with Item entry {
        if here.lvl not in self.buckets {
            self.buckets[here.lvl] = [];
        }
        self.buckets[here.lvl].append(here.val);
        for c in [->:Branch:->] {
            c.lvl = here.lvl + 1;
        }
        visit [->:Branch:->];
    }
}

with entry {
    n1 = Item(val=1);
    n2 = Item(val=2);
    n3 = Item(val=3);
    n4 = Item(val=4);
    n5 = Item(val=5);
    n6 = Item(val=6);
    n7 = Item(val=7);

    root ++> n1;
    n1 +>:Branch:+> n2;
    n1 +>:Branch:+> n3;
    n2 +>:Branch:+> n4;
    n3 +>:Branch:+> n5;
    n3 +>:Branch:+> n6;
    n5 +>:Branch:+> n7;

    w = root spawn LevelOrder();
    levels = [w.buckets[k] for k in sorted(w.buckets.keys())];
    print(levels);
}

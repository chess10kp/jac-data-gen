node ANode {
    has val: int;
}

walker Average {
    has total: int = 0;
    has count: int = 0;

    can chk with ANode entry {
        self.total += here.val;
        self.count += 1;
        visit [-->];
    }
}

with entry {
    a = ANode(val=10);
    b = ANode(val=20);
    c = ANode(val=30);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn Average();
    print(round(w.total / w.count));
}

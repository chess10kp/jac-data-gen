node TNode {
    has val: int;
}

walker LastValue {
    has last: int = 0;

    can chk with TNode entry {
        self.last = here.val;
        visit [-->];
    }
}

with entry {
    a = TNode(val=1);
    b = TNode(val=2);
    c = TNode(val=3);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn LastValue();
    print(w.last);
}

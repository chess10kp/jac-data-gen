node TNode {
    has val: int;
}

walker Product {
    has result: int = 1;

    can mul with TNode entry {
        self.result *= here.val;
        visit [-->];
    }
}

with entry {
    a = TNode(val=2);
    b = TNode(val=3);
    c = TNode(val=4);
    root ++> a;
    a ++> b;
    a ++> c;
    w = a spawn Product();
    print(w.result);
}

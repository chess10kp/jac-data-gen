node SNode {
    has val: int;
}

walker Contains {
    has target: int;
    has found: bool = False;

    can chk with SNode entry {
        if here.val == self.target {
            self.found = True;
            disengage;
        }
        visit [-->];
    }
}

with entry {
    a = SNode(val=5);
    b = SNode(val=8);
    c = SNode(val=13);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn Contains(target=13);
    print(w.found);
}

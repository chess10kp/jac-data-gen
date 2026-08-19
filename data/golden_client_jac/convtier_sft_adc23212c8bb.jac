node LLNode {
    has val: int;
}

edge Next {}

walker SumList {
    has total: int = 0;

    can add with LLNode entry {
        self.total += here.val;
        visit [-->];
    }
}

with entry {
    n1 = LLNode(val=10);
    n2 = LLNode(val=20);
    n3 = LLNode(val=30);
    root ++> n1;
    n1 +>:Next:+> n2;
    n2 +>:Next:+> n3;
    w = n1 spawn SumList();
    print(w.total);
}

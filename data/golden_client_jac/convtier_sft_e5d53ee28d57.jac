node QNode {
    has val: int;
}

walker SumSquares {
    has total: int = 0;

    can chk with QNode entry {
        self.total += here.val ** 2;
        visit [-->];
    }
}

with entry {
    a = QNode(val=1);
    b = QNode(val=2);
    c = QNode(val=3);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn SumSquares();
    print(w.total);
}

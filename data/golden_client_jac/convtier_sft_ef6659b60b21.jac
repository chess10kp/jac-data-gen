node Parent {
    has name: str;
}

node Child {
    has val: int;
}

walker SumChildren {
    has total: int = 0;

    can at_parent with Parent entry {
        visit [-->];
    }

    can at_child with Child entry {
        self.total += here.val;
    }
}

with entry {
    p = Parent(name="p");
    c1 = Child(val=10);
    c2 = Child(val=20);
    root ++> p;
    p ++> c1;
    p ++> c2;
    w = p spawn SumChildren();
    print(w.total);
}

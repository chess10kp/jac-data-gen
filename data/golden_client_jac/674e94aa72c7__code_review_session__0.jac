node Item {}
edge Start {}
edge Next {}
edge End {}

with entry {
    a = Item();
    b = Item();
    c = Item();
    d = Item();

    # Single typed chain: root -Start-> a -Next-> b -Next-> c -End-> d
    root +>: Start :+> a +>: Next :+> b +>: Next :+> c +>: End :+> d;
}

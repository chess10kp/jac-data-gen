node Item {}
edge Start {}
edge Next {}
edge End {}

with entry {
    a = Item();
    b = Item();
    c = Item();
    d = Item();

    # Build chains in one expression
    root ++> a ++> b ++> c ++> d;

    # With typed edges
    root +>: Start :+> a +>: Next :+> b +>: Next :+> c +>: End :+> d;
}

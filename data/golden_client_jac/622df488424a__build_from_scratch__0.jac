walker:priv MyWalker {
    can work with Root entry {
        report ["item1", "item2"];
        report {"count": 2};
    }
}

with entry {
    result = root spawn MyWalker();
    data = result.reports[0];
    meta = result.reports[1];
}

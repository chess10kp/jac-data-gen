walker:priv MyWalker {
    can work with Root entry {
        report "data";
    }
}

with entry {
    result = root spawn MyWalker();
    data = result.reports[0] if result.reports else None;
}

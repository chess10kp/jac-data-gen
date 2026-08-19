walker:priv MyWalker {
    can work with Root entry {
        report ["item1", "item2"];
        report {"count": 2};
    }
}

with entry {
    result = root spawn MyWalker();

    # Bad: Magic indices
    data = result.reports[0];
    meta = result.reports[1];

    # Good: Document or structure clearly
    # reports[0]: List of items
    # reports[1]: Metadata object
    data = result.reports[0] if result.reports else [];
    meta = result.reports[1] if len(result.reports) > 1 else {};
}

"""block_models.tap_tupoff

    Return the input tuple with constant offset added to both elements
    """
def tap_tupoff(tup: tuple = (), off: int = 0) -> tuple {
    assert len(tup) == 2, (
        "block_models.py.tap_tupoff wants 2-tuple, got %d-tuple" % (len(tup), )
    );
    return (tup[0] + off, tup[1] + off);
}
test "empty list" {
    result = process([]);
    assert result == [];
}

test "single item" {
    result = process([1]);
    assert len(result) == 1;
}

test "large list" {
    result = process(list(range(1000)));
    assert len(result) == 1000;
}

"""Extract the numeric portion from a WALS feature value string."""
def _value_sorter(feature_value: str) -> int {
    toks = feature_value.split(" ", maxsplit=1);
    assert len(toks) == 2, "%s: Invalid feature value" % feature_value;
    val = int(toks[0]);
    assert val > 0, "%s: Feature value should be positive. Found %d" % (feature_value, val);
    val
}
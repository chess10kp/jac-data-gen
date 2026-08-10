"""Melts several dicts into one, optionally raising on duplicate keys."""
def merge_dicts(*dicts: dict[str, object], **kwargs: bool) -> dict[str, object] {
    merged_dict = {};
    for d in dicts {
        merged_dict.update(d);
    }
    if kwargs.get('check_conflicts') {
        assert len(merged_dict) == sum(map(len, dicts)), 'dicts have duplicate keys';
    }
    return merged_dict;
}
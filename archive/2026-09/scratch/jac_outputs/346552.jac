"""Prepare filters (kwargs{}) for django queryset
    where fields contain digits are checked like = | > | >= | < | <=

    >>> mongodb_int_filter(10, '1')
    10.0
    >>> mongodb_int_filter(10, '2')
    {'$gt': 10.0}
    >>> mongodb_int_filter(10, '3')
    {'$gte': 10.0}
    >>> mongodb_int_filter(10, '4')
    {'$lt': 10.0}
    """
def mongodb_int_filter(base_field: str | int, base_field_type: str) -> float | str | dict[str, float] {
    q: float | str | dict[str, float] = '';
    if base_field != '' {
        if base_field_type == '1' {
            q = float(base_field);
        }
        if base_field_type == '2' {
            q = {'$gt': float(base_field)};
        }
        if base_field_type == '3' {
            q = {'$gte': float(base_field)};
        }
        if base_field_type == '4' {
            q = {'$lt': float(base_field)};
        }
        if base_field_type == '5' {
            q = {'$lte': float(base_field)};
        }
    }
    return q;
}
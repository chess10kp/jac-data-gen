"""Prepare filters (kwargs{}) for django queryset for mongodb
       where fields contain strings are checked like
       exact | startswith | contains | endswith

    >>> mongodb_str_filter(21, '1')
    '21'
    >>> mongodb_str_filter(21, '2')
    {'$regex': '^21'}
    >>> mongodb_str_filter(21, '3')
    {'$regex': '.*21.*'}
    >>> mongodb_str_filter(21, '4')
    {'$regex': '21$'}
    """
def mongodb_str_filter(base_field: Any, base_field_type: Any) -> object {
    q = '';
    base_field = str(base_field);
    if (base_field != '') {
        if (base_field_type == '1') {
            q = base_field;
        }
        if (base_field_type == '2') {
            q = {'$regex': str(('^' + base_field))};
        }
        if (base_field_type == '3') {
            q = {'$regex': str(('.*' + base_field + '.*'))};
        }
        if (base_field_type == '4') {
            q = {'$regex': str((base_field + '$'))};
        }
    }
    return q;
}
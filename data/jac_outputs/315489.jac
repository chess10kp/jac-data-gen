"""Returns equivalent dtype for input `pgtype`."""
def pg2dtypes(pgtype: str) -> str {
    mapping = {
        'date': 'datetime64[ns]',
        'number': 'float64',
        'string': 'object',
        'boolean': 'bool',
        'geometry': 'object'
    };
    return mapping.get(str(pgtype), 'object');
}
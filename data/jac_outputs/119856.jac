"""
    Convert instances of textx types to python types.
    """
def convert(value: Any, _type: Any) -> object {
    return {
        'BOOL': lambda (x: Any) { ((x == '1') or (x.lower() == 'true')); },
        'INT': lambda (x: Any) { int(x); },
        'FLOAT': lambda (x: Any) { float(x); },
        'STRING': lambda (x: Any) { x[1:-1].replace(r'\"', r'"').replace(r"\'", "'"); }
    }.get(
        _type, lambda (x: Any) { x; }
    )(
        value
    );
}
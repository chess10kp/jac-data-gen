"""Attempt pulling python 3 function annotations off of 'func' for
use as a signals type information. Returns an ordered nested tuple
of (return_type, (arg_type1, arg_type2, ...)). If the given function
does not have annotations then (None, tuple()) is returned.
"""
def get_signal_annotations(func: Callable) -> tuple[`type | None, tuple[`type, ...]] {
    arg_types = tuple();
    return_type = None;
    if hasattr(func, '__annotations__') {
        import inspect;
        spec = inspect.getfullargspec(func);
        arg_types = tuple(
            spec.annotations[arg]
            for arg in spec.args
            if arg in spec.annotations
        );
        if 'return' in spec.annotations {
            return_type = spec.annotations['return'];
        }
    }
    return (return_type, arg_types);
}
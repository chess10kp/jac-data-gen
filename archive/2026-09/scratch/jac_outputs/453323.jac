"""Convert time scale dict to seconds."""
def get_seconds(value: int | float, scale: str) -> int | float {
    scales = {
        'seconds': lambda (x: int | float) { x; },
        'minutes': lambda (x: int | float) { x * 60; },
        'hours': lambda (x: int | float) { x * 60 * 60; },
        'days': lambda (x: int | float) { x * 60 * 60 * 24; },
        'weeks': lambda (x: int | float) { x * 60 * 60 * 24 * 7; },
        'months': lambda (x: int | float) { x * 60 * 60 * 24 * 30; },
        'years': lambda (x: int | float) { x * 60 * 60 * 24 * 365; }
    };
    return scales[scale](value) as int | float;
}
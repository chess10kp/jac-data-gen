"""Workflow used to test the introspective argument parser."""
def dummy_flow(
    positional_str: str,
    positional_bool: bool,
    positional_int: int,
    positional_float: float,
    optional_str: str = 'default',
    optional_bool: bool = False,
    optional_int: int = 0,
    optional_float: float = 1.0,
    optional_float_2: float = 2.0
) -> tuple[str, bool, int, float, str, bool, int, float, float] {
    (
        positional_str,
        positional_bool,
        positional_int,
        positional_float,
        optional_str,
        optional_bool,
        optional_int,
        optional_float,
        optional_float_2
    )
}
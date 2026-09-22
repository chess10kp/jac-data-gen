"""An example entry point for testing.

    The rest of the function __doc__ is ignored by the entrypoint library.
    foo -> a foo value.
    bar -> a bar value.
    baz -> a baz value.

    Returns a string indicating what was passed in."""
def example(foo: str | int | float | bool, bar: str | int | float | bool, baz: str | int | float | bool) -> str {
    return f'foo={foo}, bar={bar}, baz={baz}';
}
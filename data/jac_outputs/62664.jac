"""Example target function for example-allow."""
def example_allow(actuator: object, *extra_args: object, **extra_kwargs: object) -> dict[str, int | str] {
    return dict(
        status=400, status_text='this is an example action, it returns this message'
    );
}
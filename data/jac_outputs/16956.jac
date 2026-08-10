"""Return a new form with ``prefix_length`` chars removed from left."""
def without_fixed_prefix(
    form: tuple[str, str, str, float, list[str]],
    prefix_length: int
) -> tuple[str, str, str, float, list[str]] {
    (word, tag, normal_form, score, methods_stack) = form;
    return (
        word[prefix_length:],
        tag,
        normal_form[prefix_length:],
        score,
        methods_stack
    );
}
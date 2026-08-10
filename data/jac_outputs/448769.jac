"""Expected assignment_no_params_with_context __doc__"""
def assignment_no_params_with_context(context: dict[str, str]) -> str {
    return (
        "assignment_no_params_with_context - Expected result (context value: %s)"
        % context['value']
    );
}
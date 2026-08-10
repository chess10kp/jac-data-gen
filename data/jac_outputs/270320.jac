"""Expected inclusion_params_and_context __doc__"""
def inclusion_params_and_context(context: dict[str, str], arg: str) -> dict[str, str] {
    return {
        "result": "inclusion_params_and_context - Expected result (context value: %s): %s" % (context['value'], arg)
    };
}
"""The basic evaluator for backquoted strings"""
def basic_backquote_string_evaluator(val: str) -> str | int | float | bool {
    return eval(val, globals(), locals());
}
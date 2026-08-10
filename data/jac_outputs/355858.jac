"""Evaluates initial values "= { ... }"."""
def initialiser_array(evaluator: Any, ast: Any, state: Any) -> object {
    vals = `list(
        map(lambda (var: Any) { evaluator.eval_ast(var, state); }, ast["vals"])
    );
    return vals;
}
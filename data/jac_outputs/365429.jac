"""Create an example dictionary."""
def _create_example(product_id: Any, question: Any, answer: Any) -> object {
    return {'product_id': product_id, 'context': question, 'response': answer};
}
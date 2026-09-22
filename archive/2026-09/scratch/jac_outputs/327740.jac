"""
    Return the test node, typically a _pytest.Function.
    Provided arg may be the node already, or the pytest request

    :param request_or_item:
    :return:
    """
def get_test_node(request_or_item: Any) -> object {
    try {
        return request_or_item.node;
    } except AttributeError {
        return request_or_item;
    }
}
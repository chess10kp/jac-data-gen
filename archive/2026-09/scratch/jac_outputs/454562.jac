"""argument of doc_string"""
def doc_arg(name: Any, brief: Any) -> object {
    return "    :param {0}: {1}".format(name, brief);
}
"""
    Helper function to the Evaluator.to_property_di_graph() method that
    packages the dictionaries returned by the "associate" family of
    functions and then supplies the master dict (one_dict) to the Vertex
    obj as kwargs.
    """
def build_dict(arg: list[dict[str, str]]) -> dict[str, str] {
    one_dict = {};
    for ar in arg {
        one_dict.update(ar);
    }
    return one_dict;
}
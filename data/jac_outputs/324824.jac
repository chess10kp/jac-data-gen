"""Turn the serialized key/value pairs back into a dict."""
def unwrap_args(form_query_argument_list: list[dict[str, str]]) -> dict[str, str] {
    kwargs = {};
    for arg in form_query_argument_list {
        kwargs[arg['key']] = arg['value'];
    }
    return kwargs;
}
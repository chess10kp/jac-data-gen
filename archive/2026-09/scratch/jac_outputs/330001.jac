"""Extract HTTP methods from a tagged link or resource decorator."""
def __get_http_methods(tagged_item: dict[str, dict[str, list[str] | str] | list[str]]) -> list[str] {
    def default_method(args: list[str]) -> list[str] {
        return ['POST'] if len(args) > 0 else ['GET'];
    }
    tag_args = tagged_item.get('argspec');
    http_methods = (tagged_item.get('decorator_kwargs') as dict[str, list[str] | str]).get(
        'method', default_method(tag_args as list[str])
    );
    if not isinstance(http_methods, list) {
        http_methods = [http_methods];
    }
    return http_methods;
}
"""Construct api error according to jsonapi 1.0."""
def jsonapi_errors(jsonapi_errors: list[object]) -> dict[str, object] {
    return {
        'errors': [jsonapi_error for jsonapi_error in jsonapi_errors],
        'jsonapi': {'version': '1.0'}
    };
}
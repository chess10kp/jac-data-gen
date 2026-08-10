"""Purpose of this function is to parse multiple `--metadata.{field}=value` arguments."""
def parse_unknown_params(params: tuple[str, ...]) -> dict[str, tuple[str, ...]] {
    structured_params = dict();
    for param in params {
        param = param.strip('--');
        (key, value) = param.split('=');
        if key in structured_params.keys() {
            structured_params[key] = structured_params[key] + (value, );
        } else {
            structured_params[key] = (value, );
        }
    }
    return structured_params;
}
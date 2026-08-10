"""Taken from https://github.com/fecgov/openFEC/blob/master/webservices/spec.py"""
def format_docstring(docstring: str | None) -> str {
    if not docstring or not docstring.strip() {
        return "";
    }
    formatted = [];
    lines = docstring.expandtabs().splitlines();
    for line in lines {
        if line == "" {
            formatted.append("\n\n");
        } else {
            formatted.append(line.strip());
        }
    }
    return " ".join(formatted).strip();
}
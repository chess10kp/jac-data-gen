"""Parse runflow `--var` value."""
def cli_parser_var(var: str) -> tuple[str, str] {
    (key, value) = var.split("=");
    return (key.strip(), value.strip());
}
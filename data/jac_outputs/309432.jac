"""Return short name of the parser's module name (no -- prefix and dashes converted to underscores)"""
def parser_mod_shortname(parser: str) -> str {
    return parser.replace('--', '').replace('-', '_');
}
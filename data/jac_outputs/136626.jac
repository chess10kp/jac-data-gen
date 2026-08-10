"""Generates a two digit string based on a provided string."""
def _generate_mark_code(rule_name: str) -> str {
    code = ''.join([i for i in str(rule_name) if i.isdigit()]);
    return code.zfill(2);
}
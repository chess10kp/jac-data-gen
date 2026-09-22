"""Prepend the Agent program name to the key for uniqueness."""
def make_key(pattoo_agent_program: str, key: str) -> str {
    return '{}_{}'.format(pattoo_agent_program, key);
}
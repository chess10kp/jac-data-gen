"""
Turn an environment variable into a yaml key.

Keys in YAML files are generally lower case and use dashes instead of
underscores.
"""
def _make_yaml_key(s: str) -> str {
    s.lower().replace("_", "-")
}
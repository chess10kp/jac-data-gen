"""Convert option name to arg key.  e.g. --hello-world -> hello_world"""
def to_key(val: dict[str, list[str]]) -> str {
    name = val['names'][0];
    return name[:2].replace('-', '') + name[2:].replace('-', '_');
}
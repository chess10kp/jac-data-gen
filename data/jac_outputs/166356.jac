"""Generate an xdot graph attribute string."""
def graph_attr_string(attrs: dict[str, int | str]) -> str {
    attrs_strs = [f'"{str(k)}"="{str(v)}"' for (k, v) in attrs.items()];
    return ';\n'.join(attrs_strs) + ';\n';
}
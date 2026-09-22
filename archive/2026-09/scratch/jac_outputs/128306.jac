"""Create HTML td for graphviz."""
def viz_td(body: str, port: str | None = None, align: str = "CENTER") -> str {
    port_text = "" if port is None else 'PORT="{}"'.format(port);
    return '<TD {port_text} ALIGN="{align}">{body}</TD>'.format(**locals());
}
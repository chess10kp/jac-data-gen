"""Generates a graphviz digraph source description using HTML-like labels with the specified styling."""
def write_feed_source(left: str, center: str, right: str, max_width: float) -> str {
    feed_string = 'digraph {{\n\tgraph [rankdir=LR size={}];'.format(max_width);
    feed_string += '\n\tnode [fontsize=12 width=0.35 shape=plaintext];';
    feed_string += '\n\tfeed [label=< <table border="0" cellborder="1" cellspacing="0" cellpadding="8"><tr>';
    feed_string += '<td>{}</td>'.format(left);
    feed_string += '<td width="16">{}</td>'.format(center);
    feed_string += '<td>{}</td>'.format(right);
    feed_string += '</tr></table>>];\n}';
    return feed_string;
}
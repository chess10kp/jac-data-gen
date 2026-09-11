"""DOM-like document tree.

Elements carry ``tag`` / ``el_id`` payload plus ``parent`` / ``children``
pointers. Depth queries ascend; selector queries descend. Outline
rendering is capped at ``MAX_OUTLINE_DEPTH`` levels -- a documented
domain limit, not scaffolding.
"""

MAX_OUTLINE_DEPTH = 3


class Element:
    def __init__(self, tag, el_id):
        self.tag = tag
        self.el_id = el_id
        self.parent = None       # Element | None (document root)
        self.children = []       # list[Element]


def append_child(parent_el, tag, el_id):
    """Attach a new element to ``parent_el`` (None for the document root)."""
    el = Element(tag, el_id)
    if parent_el is not None:
        el.parent = parent_el
        parent_el.children.append(el)
    return el


def element_depth(el):
    """1-based depth of ``el`` measured up to the document root."""
    if el.parent is None:
        return 1
    return 1 + element_depth(el.parent)


def query_selector_all(el, tag):
    """All ``el_id``s at or below ``el`` whose tag matches, sorted."""
    hits = []
    if el.tag == tag:
        hits.append(el.el_id)
    for c in el.children:
        hits.extend(query_selector_all(c, tag))
    return sorted(hits)


def render_outline(el):
    """Labels down to MAX_OUTLINE_DEPTH levels, sorted for stable output."""
    labels = []

    def walk(node, depth):
        if depth > MAX_OUTLINE_DEPTH:
            return
        labels.append(f"{node.tag}#{node.el_id}")
        for c in node.children:
            walk(c, depth + 1)

    walk(el, 1)
    return sorted(labels)


def subtree_width(el):
    """Number of elements at or below ``el``, counting it."""
    return 1 + sum(subtree_width(c) for c in el.children)

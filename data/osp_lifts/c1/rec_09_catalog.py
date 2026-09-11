"""Nested product catalog.

Categories nest through ``parent`` / ``subcats`` pointers; stocked
items are price payloads hanging off categories. Subtotals and stock
counts recursively descend; leaf discovery finds saleable nodes.
"""


class Category:
    def __init__(self, name):
        self.name = name
        self.prices = []         # int item prices stocked directly here
        self.parent = None       # Category | None (catalog root)
        self.subcats = []        # list[Category]


def add_category(parent, name):
    """Create a subcategory under ``parent`` (None for catalog root)."""
    cat = Category(name)
    if parent is not None:
        cat.parent = parent
        parent.subcats.append(cat)
    return cat


def stock_item(cat, price):
    """Stock one item at ``price`` directly in ``cat``."""
    cat.prices.append(price)


def category_subtotal(cat):
    """Total value of everything stocked in ``cat``'s subtree."""
    total = sum(cat.prices)
    for s in cat.subcats:
        total += category_subtotal(s)
    return total


def item_count(cat):
    """Number of items stocked in ``cat``'s subtree."""
    count = len(cat.prices)
    for s in cat.subcats:
        count += item_count(s)
    return count


def leaf_categories(root):
    """Names of categories with no subcategories at or below root, sorted."""
    leaves = []

    def walk(node):
        if not node.subcats:
            leaves.append(node.name)
        for s in node.subcats:
            walk(s)

    walk(root)
    return sorted(leaves)


def priciest_branch(cat):
    """Longest chain of nested subcategories starting at ``cat`` (it counts)."""
    best = 0
    for s in cat.subcats:
        candidate = priciest_branch(s)
        if candidate > best:
            best = candidate
    return 1 + best

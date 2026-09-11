"""Biological taxonomy tree.

Taxa nest through ``parent`` / ``subs`` pointers. Breadcrumbs ascend
from a species to the root of classification; species counts and
membership checks descend through subordinate ranks.
"""


class Species:
    def __init__(self, name, rank):
        self.name = name
        self.rank = rank         # e.g. kingdom, genus, species
        self.parent = None       # Species | None (root taxon)
        self.subs = []           # list[Species], subordinate taxa


def classify(parent, name, rank):
    """Place a taxon under ``parent`` (None for the root) and return it."""
    t = Species(name, rank)
    if parent is not None:
        t.parent = parent
        parent.subs.append(t)
    return t


def breadcrumb(taxon):
    """``rank:name`` labels from the root down to ``taxon``, inclusive."""
    if taxon.parent is None:
        return [f"{taxon.rank}:{taxon.name}"]
    return breadcrumb(taxon.parent) + [f"{taxon.rank}:{taxon.name}"]


def species_count(taxon):
    """Number of rank=='species' taxa at or below ``taxon``."""
    total = 1 if taxon.rank == "species" else 0
    for s in taxon.subs:
        total += species_count(s)
    return total


def contains(taxon, name):
    """True when a taxon named ``name`` exists at or below ``taxon``."""
    if taxon.name == name:
        return True
    for s in taxon.subs:
        if contains(s, name):
            return True
    return False


def rank_spread_list(taxon):
    """Distinct ranks in the subtree, sorted (public helper)."""
    return sorted(_collect_ranks(taxon))


def _collect_ranks(taxon):
    ranks = {taxon.rank}
    for s in taxon.subs:
        ranks.update(_collect_ranks(s))
    return ranks

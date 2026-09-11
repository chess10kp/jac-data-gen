"""Harness: exercise CmsCatalog.remove_category, assert post-state, exit 0."""
from rec_22_cms_category_removal import CmsCatalog


def build():
    """Fixture (deterministic):

    news
      world
      politics
    sports
      tennis
    shared "reactions" cross-listed under world AND tennis (diamond).
    """
    cat = CmsCatalog()
    cat.add("news", "News")
    cat.add("world", "World", parent_id="news")
    cat.add("politics", "Politics", parent_id="news")
    cat.add("sports", "Sports")
    cat.add("tennis", "Tennis", parent_id="sports")
    cat.add("reactions", "Reactions", parent_id="world")
    cat.cross_list("reactions", "tennis")     # diamond: reachable twice
    return cat


def test_removes_full_closure_with_diamond_dedup():
    cat = build()
    removed = cat.remove_category("news")
    assert removed == ["news", "politics", "reactions", "world"], removed
    assert "world" not in cat.categories
    assert "reactions" not in cat.categories   # deleted exactly once
    assert set(cat.categories) == {"sports", "tennis"}
    assert cat.titles() == ["Sports", "Tennis"]


def test_unknown_and_stale_refs_tolerated():
    cat = build()
    assert cat.remove_category("ghost") == []
    # simulate a stale reference from another writer
    cat.categories["tennis"].parent_id = "deleted-long-ago"
    assert cat.remove_category("deleted-long-ago") == []
    assert cat.children_of("deleted-long-ago") == []
    assert cat.children_of("ghost") == []
    assert "tennis" in cat.categories


def test_leaf_removal_keeps_rest_intact():
    cat = build()
    removed = cat.remove_category("politics")
    assert removed == ["politics"]
    assert cat.children_of("news") == ["world"]
    assert cat.titles() == ["News", "Reactions", "Sports", "Tennis", "World"]


if __name__ == "__main__":
    test_removes_full_closure_with_diamond_dedup()
    test_unknown_and_stale_refs_tolerated()
    test_leaf_removal_keeps_rest_intact()
    print("rec_22 ref harness: all assertions passed")

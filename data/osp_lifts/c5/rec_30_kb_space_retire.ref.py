"""Harness: exercise KbRegistry.retire_space, assert post-state, exit 0."""
from rec_30_kb_space_retire import KbRegistry


def build():
    """Fixture:

    space -> guide -> glossary
          -> faq        (external -> faq: FAQ externally referenced)
    external -> faq, guide   (guide has ext_links too)
    """
    kb = KbRegistry()
    kb.add_page("space", "Space Home")
    kb.add_page("guide", "Guide", parent_id="space")
    kb.add_page("faq", "FAQ", parent_id="space")
    kb.add_page("glossary", "Glossary", parent_id="guide")
    kb.add_page("external", "External Notes")
    assert kb.link("external", "faq")
    assert kb.link("external", "guide")   # guide also referenced outside
    return kb


def test_retire_spares_externally_linked_pages():
    kb = build()
    spared = kb.retire_space("space")
    # both faq and guide carry incoming links from `external`; the closure
    # stops at each of them, so glossary survives under spared guide
    assert spared == ["faq", "guide"], spared
    assert not kb.exists("space")
    assert kb.exists("faq") and kb.exists("guide") and kb.exists("glossary")


def test_unreferenced_branch_fully_retires():
    kb = KbRegistry()
    kb.add_page("solo_space", "Solo")
    kb.add_page("deep", "Deep", parent_id="solo_space")
    kb.add_page("other", "Other")
    kb.link("deep", "other")
    spared = kb.retire_space("solo_space")
    assert spared == []                    # nothing external points inside
    assert not kb.exists("solo_space") and not kb.exists("deep")
    assert kb.exists("other")
    # deep's outbound link died with it; other's ext_links back to 0


def test_unknown_and_dangling_tolerated():
    kb = build()
    assert kb.retire_space("ghost") == []
    assert kb.link("external", "vanished") is False
    kb.pages["external"].links.append("gone_somewhere")   # stale entry
    # readers skip dangling targets silently
    assert kb.follow("external") == ["faq", "guide"]
    spared = kb.retire_space("space")
    assert spared == ["faq", "guide"]
    assert kb.follow("external") == ["faq", "guide"]      # unchanged


if __name__ == "__main__":
    test_retire_spares_externally_linked_pages()
    test_unreferenced_branch_fully_retires()
    test_unknown_and_dangling_tolerated()
    print("rec_30 ref harness: all assertions passed")

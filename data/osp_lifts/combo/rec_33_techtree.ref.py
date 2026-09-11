"""Reference harness for rec_33_techtree (game tech tree). Exit 0."""
import sys

sys.path.insert(0, "/home/jac/repos/jac_llm_data/data/osp_lifts/combo")
from rec_33_techtree import TechTree


def build():
    t = TechTree()
    t.add_branch("empire")
    t.add_branch("military", parent="empire")
    t.add_branch("economy", parent="empire")
    t.add_tech("swords", "military", 1)
    t.add_tech("armor", "military", 2)
    t.add_tech("mining", "economy", 1)
    t.add_tech("currency", "economy", 2)
    t.require("armor", "swords")
    t.require("currency", "mining")
    return t


def test_structure():
    t = build()
    assert sorted(t.branches) == ["economy", "empire", "military"]
    assert t.subtree_techs("empire") == ["armor", "currency", "mining", "swords"]
    assert t.subtree_techs("economy") == ["currency", "mining"]
    try:
        t.add_branch("empire")
        raise AssertionError("expected duplicate branch error")
    except ValueError:
        pass
    try:
        t.add_tech("x", "ghost", 1)
        raise AssertionError("expected KeyError")
    except KeyError:
        pass


def test_prereq_walk():
    t = build()
    assert t.remaining_prereqs(set(), "armor") == ["swords"]
    assert t.remaining_prereqs({"swords"}, "armor") == []
    assert t.can_research({"swords"}, "armor")
    assert not t.can_research(set(), "armor")
    assert t.era_of("currency") == 2


def test_chain_and_cycle():
    t = build()
    # chain: gunpowder -> armor -> swords
    t.add_tech("gunpowder", "military", 3)
    t.require("gunpowder", "armor")
    assert t.remaining_prereqs({"swords"}, "gunpowder") == ["armor"]
    assert t.remaining_prereqs(set(), "gunpowder") == ["armor", "swords"]
    # cycle must terminate via guard
    t.require("swords", "gunpowder")
    assert t.remaining_prereqs(set(), "gunpowder") == ["armor", "swords"]
    assert t.can_research({"swords", "armor", "gunpowder"}, "swords")


test_structure()
test_prereq_walk()
test_chain_and_cycle()
print("rec_33 ref OK")
sys.exit(0)

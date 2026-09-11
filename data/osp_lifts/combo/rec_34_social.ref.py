"""Reference harness for rec_34_social (social platform). Exit 0."""
import sys

sys.path.insert(0, "/home/jac/repos/jac_llm_data/data/osp_lifts/combo")
from rec_34_social import SocialNetwork


def build():
    n = SocialNetwork()
    n.add_community("site")
    n.add_community("gaming", parent="site")
    n.add_community("retro", parent="gaming")
    n.add_community("news", parent="site")
    for u in ("ann", "bob", "cy", "dee"):
        n.users.setdefault(u, set())
        n.follows.setdefault(u, set())
        n.blocks.setdefault(u, set())
    n.join("ann", "retro")
    n.join("bob", "retro")
    n.join("cy", "gaming")
    n.join("dee", "news")
    return n


def test_structure():
    n = build()
    assert sorted(n.communities) == ["gaming", "news", "retro", "site"]
    assert sorted(n.users) == ["ann", "bob", "cy", "dee"]
    try:
        n.add_community("site")
        raise AssertionError("expected duplicate community error")
    except ValueError:
        pass
    try:
        n.join("eve", "ghost")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass


def test_members_within():
    n = build()
    assert n.members_within("retro") == ["ann", "bob"]
    # gaming includes retro's members when include_sub=True
    assert n.members_within("gaming") == ["ann", "bob", "cy"]
    assert n.members_within("gaming", include_sub=False) == ["cy"]
    assert n.members_within("site") == ["ann", "bob", "cy", "dee"]


def test_follow_and_block_propagation():
    n = build()
    n.follow("ann", "bob")
    n.follow("bob", "ann")
    assert n.circle("ann") == ["bob"]
    n.block("ann", "bob")
    # postcondition: follows severed both ways, blocks symmetric
    assert n.circle("ann") == []
    assert n.common_follows("ann", "bob") == []
    try:
        n.follow("ann", "bob")
        raise AssertionError("expected blocked error")
    except ValueError:
        pass


def test_circle_bfs_and_cycle():
    n = build()
    n.follow("ann", "bob")
    n.follow("bob", "cy")
    n.follow("cy", "dee")
    assert n.circle("ann") == ["bob", "cy", "dee"]
    # cycle: dee -> ann terminates the walk
    n.follow("dee", "ann")
    assert n.circle("ann") == ["bob", "cy", "dee"]
    # diamond: two paths to cy, collected once
    n2 = build()
    n2.follow("ann", "bob")
    n2.follow("ann", "cy")
    n2.follow("bob", "dee")
    n2.follow("cy", "dee")
    got = n2.circle("ann")
    assert len(got) == len(set(got))
    assert got == ["bob", "cy", "dee"]


def test_common():
    n = build()
    n.follow("ann", "cy")
    n.follow("bob", "cy")
    n.follow("ann", "dee")
    assert n.common_follows("ann", "bob") == ["cy"]


test_structure()
test_members_within()
test_follow_and_block_propagation()
test_circle_bfs_and_cycle()
test_common()
print("rec_34 ref OK")
sys.exit(0)

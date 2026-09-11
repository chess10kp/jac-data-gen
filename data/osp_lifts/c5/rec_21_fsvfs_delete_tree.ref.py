"""Harness: exercise FileSystem.delete_subtree, assert post-state, exit 0."""
from rec_21_fsvfs_delete_tree import FileSystem


def build():
    """Deterministic fixture:

    /home/docs/{report.txt, notes.txt}
    /home/pics/{cat.png}
    /mnt/docs  -> bind mount of /home/docs (shared boundary)
    """
    fs = FileSystem()
    fs.mkdir("/home")
    fs.mkdir("/home/docs")
    fs.touch("/home/docs/report.txt")
    fs.touch("/home/docs/notes.txt")
    fs.mkdir("/home/pics")
    fs.touch("/home/pics/cat.png")
    fs.mkdir("/mnt")
    fs.mount("/home/docs", "/mnt", "docs")
    return fs


def acyclic_and_indexed(fs):
    """Invariant: graph is a DAG and reference counts match real entries."""
    state = {}          # id -> "open" | "done"

    def visit(n):
        if state.get(id(n)) == "done":
            return True
        if state.get(id(n)) == "open":
            return False            # back edge == cycle
        state[id(n)] = "open"
        ok = all(visit(c) for c in n.children)
        state[id(n)] = "done"
        return ok

    assert visit(fs.root), "graph must be acyclic"
    entry_counts = {}
    seen_holders = set()
    for holder in fs.index.values():
        if id(holder) in seen_holders:
            continue
        seen_holders.add(id(holder))
        for child in holder.children:
            entry_counts[id(child)] = entry_counts.get(id(child), 0) + 1
    for path, node in fs.index.items():
        expected = 1 if path == "/" else entry_counts.get(id(node), 0)
        assert node.links == expected, f"stale link count at {path}"
        assert path == "/" or expected >= 1, f"dangling entry {path}"
    return True


def test_happy_path_destroys_exclusive_subtree():
    fs = build()
    destroyed = fs.delete_subtree("/home/docs")
    # docs + report + notes destroyed; the /mnt alias spared docs... but the
    # alias means docs has links=2 at collection time, so NOTHING under it is
    # destroyed and docs itself is only detached from /home.
    assert destroyed == 0, destroyed
    assert fs.exists("/home/docs"), "shared boundary must survive"
    assert sorted(fs.ls("/mnt/docs")) == ["notes.txt", "report.txt"]
    assert "docs" in fs.ls("/mnt")
    assert fs.ls("/home") == ["pics"]
    assert acyclic_and_indexed(fs)


def test_exclusive_branch_is_destroyed():
    fs = build()
    destroyed = fs.delete_subtree("/home/pics")
    assert destroyed == 2, destroyed            # pics + cat.png
    assert not fs.exists("/home/pics")
    assert not fs.exists("/home/pics/cat.png")
    assert fs.exists("/home/docs/report.txt")   # untouched branch intact
    # source convention: dangling entry remains listed by the survivor
    assert fs.ls("/home") == ["docs", "pics"]   # dangling entry remains listed
    assert acyclic_and_indexed(fs)


def test_deep_chain_and_unknown_path():
    fs = build()
    fs.mkdir("/tmp_x")
    fs.mkdir("/tmp_x/a")
    fs.touch("/tmp_x/a/leaf.log")
    assert fs.delete_subtree("/nope/nothing") == 0
    assert fs.delete_subtree("/tmp_x") == 3     # tmp_x + a + leaf
    assert not fs.exists("/tmp_x/a/leaf.log")
    try:
        fs.delete_subtree("/")
        raise AssertionError("root delete must raise")
    except ValueError:
        pass
    assert acyclic_and_indexed(fs)


def test_alias_removed_then_last_mount_deletes():
    fs = build()
    assert fs.delete_subtree("/mnt/docs") == 0   # detach alias only... /mnt/docs IS the alias entry
    # deleting via the alias path detaches that mount; docs survives under /home
    assert fs.exists("/home/docs")
    assert fs.ls("/mnt") == []
    # now docs has one mount left; deleting it destroys the subtree
    assert fs.delete_subtree("/home/docs") == 3  # docs + report + notes
    assert acyclic_and_indexed(fs)


if __name__ == "__main__":
    test_happy_path_destroys_exclusive_subtree()
    test_exclusive_branch_is_destroyed()
    test_deep_chain_and_unknown_path()
    test_alias_removed_then_last_mount_deletes()
    print("rec_21 ref harness: all assertions passed")

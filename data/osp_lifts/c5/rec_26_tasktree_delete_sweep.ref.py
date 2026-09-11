"""Harness: exercise TaskBoard.delete_task, assert post-state, exit 0."""
from rec_26_tasktree_delete_sweep import TaskBoard


def build():
    """Fixture:

    epic
      design (open)
        wireframes (done)  -> preserved island with its subtree
          hi-fi (open, under done parent: stays alive inside the island)
      backend (open)
        api (open)
      shared_lib  (also referenced by epic2 -> holders=2, spared)
    epic2 -> shared_lib
    """
    board = TaskBoard()
    board.add("epic", "Epic")
    board.add("design", "Design")
    board.add("wireframes", "Wireframes", done=True)
    board.add("hifi", "Hi-Fi")
    board.add("backend", "Backend")
    board.add("api", "API")
    board.add("shared_lib", "Shared Lib")
    board.add("epic2", "Epic 2")
    for p, c in [("epic", "design"), ("design", "wireframes"),
                 ("wireframes", "hifi"), ("epic", "backend"),
                 ("backend", "api"), ("epic", "shared_lib"),
                 ("epic2", "shared_lib")]:
        assert board.attach(p, c)
    return board


def test_deletes_open_branch_preserves_done_island():
    b = build()
    preserved = b.delete_task("design")
    assert preserved == ["wireframes"], preserved   # island root only
    # the island keeps its whole subtree alive beneath the done root
    assert not b.exists("design")
    # the completed island survives intact beneath its done root
    assert b.exists("wireframes") and b.exists("hifi")
    assert b.exists("backend") and b.exists("api")
    # dangling back-reference swept clean
    assert b.parent_of("wireframes") is None


def test_shared_task_spared_then_gone_with_last_holder():
    b = build()
    preserved = b.delete_task("epic")
    assert "shared_lib" in preserved        # held by epic2 as well
    assert b.exists("shared_lib")
    assert not b.exists("backend")
    second = b.delete_task("epic2")         # last holder gone -> deleted
    assert second == []                     # nothing preserved this time
    assert not b.exists("shared_lib")


def test_done_root_request_and_unknown_ids():
    b = build()
    assert b.delete_task("ghost") == []
    # requesting a done task directly preserves it (no-op delete)
    assert b.delete_task("wireframes") == ["wireframes"]
    assert b.exists("wireframes")
    assert b.titles() == ["API", "Backend", "Design", "Epic", "Epic 2",
                          "Hi-Fi", "Shared Lib", "Wireframes"]


if __name__ == "__main__":
    test_deletes_open_branch_preserves_done_island()
    test_shared_task_spared_then_gone_with_last_holder()
    test_done_root_request_and_unknown_ids()
    print("rec_26 ref harness: all assertions passed")

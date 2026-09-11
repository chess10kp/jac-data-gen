"""Harness: exercise PlaylistLibrary.purge_folder, assert post-state, exit 0."""
from rec_29_playlist_folder_purge import PlaylistLibrary


def build():
    """Fixture:

    work/ -> focus/, gym/, lofi (shared with party/)
    party/ -> lofi, bangers
    """
    lib = PlaylistLibrary()
    lib.add_folder("work", "Work")
    lib.add_folder("focus", "Focus")
    lib.add_folder("gym", "Gym")
    lib.add_playlist("lofi", "Lo-Fi")
    lib.add_folder("party", "Party")
    lib.add_playlist("bangers", "Bangers")
    for p, c in [("work", "focus"), ("work", "gym"), ("focus", "lofi"),
                 ("party", "lofi"), ("party", "bangers")]:
        assert lib.file_under(p, c)
    return lib


def test_purge_destroys_tree_spared_shared_playlist():
    lib = build()
    spared = lib.purge_folder("work")
    # lofi filed under focus (doomed) AND party (survives) -> spared
    assert spared == ["lofi"], spared
    assert not lib.exists("work")
    assert not lib.exists("focus")
    assert not lib.exists("gym")
    assert lib.exists("lofi") and lib.exists("party")


def test_shared_playlist_dies_with_last_folder():
    lib = build()
    _s1 = lib.purge_folder("party")     # bangers dies; lofi spared again
    assert not lib.exists("bangers")
    assert lib.exists("lofi")
    s2 = lib.purge_folder("work")
    assert s2 == []                     # last holder gone -> destroyed
    assert not lib.exists("lofi")


def test_unknown_and_stale_refs():
    lib = build()
    assert lib.purge_folder("ghost") == []
    lib.nodes["party"].children.append("vanished")   # stale entry
    spared = lib.purge_folder("party")
    assert spared == ["lofi"]
    assert lib.labels() == ["Focus", "Gym", "Lo-Fi", "Work"]


if __name__ == "__main__":
    test_purge_destroys_tree_spared_shared_playlist()
    test_shared_playlist_dies_with_last_folder()
    test_unknown_and_stale_refs()
    print("rec_29 ref harness: all assertions passed")

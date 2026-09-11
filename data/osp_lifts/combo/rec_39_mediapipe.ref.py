"""Reference harness for rec_39_mediapipe (media pipeline). Exit 0."""
import sys

sys.path.insert(0, "/home/jac/repos/jac_llm_data/data/osp_lifts/combo")
from rec_39_mediapipe import MediaPipeline


def build():
    m = MediaPipeline()
    m.add_folder("media")
    m.add_folder("photos", parent="media")
    m.add_folder("renders", parent="media")
    m.add_asset("orig", "photos", quality=10)
    m.derive("orig", "thumb", "renders", quality=2)
    m.derive("thumb", "sprite", "renders", quality=3)
    m.add_asset("logo", "media", quality=5)
    return m


def test_structure_and_scores():
    m = build()
    assert sorted(m.folders) == ["media", "photos", "renders"]
    assert sorted(m.assets) == ["logo", "orig", "sprite", "thumb"]
    assert m.folder_score("photos") == 10
    assert m.folder_score("media") == 20   # aggregate up the tree
    try:
        m.add_folder("media")
        raise AssertionError("expected duplicate folder error")
    except ValueError:
        pass
    try:
        m.add_asset("x", "ghost")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass


def test_derivatives_closure():
    m = build()
    assert m.derivatives_of("orig") == ["sprite", "thumb"]
    assert m.derivatives_of("logo") == []
    assert m.folder_assets("media") == ["logo", "orig", "sprite", "thumb"]
    assert m.folder_assets("renders") == ["sprite", "thumb"]


def test_derivation_cycle_terminates():
    m = build()
    # adversarial cycle: orig derived from sprite
    m.derived_from["orig"] = "sprite"
    got = m.derivatives_of("orig")
    assert len(got) == len(set(got))
    assert got == ["sprite", "thumb"]


def test_purge_cascade_and_recompute():
    m = build()
    doomed = m.purge("orig")
    assert doomed == ["orig", "sprite", "thumb"]
    assert "orig" not in m.assets and "thumb" not in m.assets
    assert m.folder_score("photos") == 0
    assert m.folder_score("media") == 5    # only logo remains
    assert m.folder_assets("media") == ["logo"]
    try:
        m.purge("ghost")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass


test_structure_and_scores()
test_derivatives_closure()
test_derivation_cycle_terminates()
test_purge_cascade_and_recompute()
print("rec_39 ref OK")
sys.exit(0)

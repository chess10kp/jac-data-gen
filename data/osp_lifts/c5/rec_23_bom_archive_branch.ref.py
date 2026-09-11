"""Harness: exercise BomRegistry.archive_branch, assert post-state, exit 0."""
from rec_23_bom_archive_branch import BomRegistry


def build():
    """Fixture:

    bike
      frame
      wheels -> shared subassembly (also under spare_kit)
        spokes
    spare_kit
      wheels (shared)
      bell
    """
    bom = BomRegistry()
    for pid, name, cost in [
        ("bike", "Bike", 299.0), ("frame", "Frame", 80.0),
        ("wheels", "Wheels", 60.0), ("spokes", "Spokes", 12.0),
        ("spare_kit", "Spare Kit", 95.0), ("bell", "Bell", 5.0),
    ]:
        _p = bom.add_part(pid, name, cost)
    bom.add_component("bike", "frame")
    bom.add_component("bike", "wheels")
    bom.add_component("wheels", "spokes")
    bom.add_component("spare_kit", "wheels")   # diamond: wheels shared
    bom.add_component("spare_kit", "bell")
    return bom


def test_archives_exclusive_branch_only():
    bom = build()
    changed = bom.archive_branch("spare_kit")
    assert changed == 2, changed               # spare_kit + bell
    assert bom.is_archived("spare_kit") is True
    assert bom.is_archived("wheels") is False  # still used by bike: spared
    assert bom.is_archived("spokes") is False  # spared with its shared parent
    assert sorted(bom.active_parts()) == ["bike", "frame", "spokes", "wheels"]


def test_shared_part_archived_when_requested_directly():
    bom = build()
    assert bom.usage_count("wheels") == 2
    changed = bom.archive_branch("wheels")     # direct request overrides sharing
    assert changed == 2                        # wheels + exclusive spokes
    assert bom.is_archived("spokes") is True
    assert bom.is_archived("bike") is False
    # archiving again reports zero (idempotent)
    assert bom.archive_branch("wheels") == 0
    assert bom.archive_branch("ghost") == 0


def test_full_leaf_and_dangling_tolerance():
    bom = build()
    assert bom.archive_branch("spokes") == 1
    bom.parts["frame"].components.append("ghost_part")   # stale BOM line
    assert bom.archive_branch("bike") == 2               # bike + frame; ghost skipped
    assert bom.is_archived("bike") and bom.is_archived("frame")
    assert bom.is_archived("ghost_part") is None
    assert sorted(bom.active_parts()) == ["bell", "spare_kit", "wheels"]


if __name__ == "__main__":
    test_archives_exclusive_branch_only()
    test_shared_part_archived_when_requested_directly()
    test_full_leaf_and_dangling_tolerance()
    print("rec_23 ref harness: all assertions passed")

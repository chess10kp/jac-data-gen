"""Harness: exercise OrgDirectory.offboard, assert post-state, exit 0."""
from rec_28_org_offboard_deactivate import OrgDirectory


def build():
    """Fixture (dotted line: cto also under ceo? no -- pm dotted under cfo):

    ceo -> [cto, pm]
    cfo -> [pm(dotted), auditor]
    grants: cto:[repo, deploy], pm:[design], auditor:[repo]
    """
    d = OrgDirectory()
    for eid, nm in [("ceo", "Chief"), ("cto", "Tech"), ("pm", "Product"),
                    ("cfo", "Finance"), ("auditor", "Audit")]:
        d.hire(eid, nm)
    for m, r in [("ceo", "cto"), ("ceo", "pm"), ("cfo", "pm"),
                 ("cfo", "auditor")]:
        assert d.assign(m, r)
    for e, apps in [("cto", ["repo", "deploy"]), ("pm", ["design"]),
                    ("auditor", ["repo"])]:
        for a in apps:
            assert d.grant(e, a)
    return d


def test_offboards_closure_revokes_grants_once():
    d = build()
    gone, revoked = d.offboard("ceo")
    assert gone == ["ceo", "cto", "pm"], gone
    assert revoked == 3                      # cto 2 + pm 1
    assert d.active_people() == ["auditor", "cfo"]
    # pm reached twice via dotted line: grants revoked exactly once
    assert d.holders_of("repo") == 1         # only auditor left
    assert d.holders_of("deploy") == 0
    assert d.holders_of("design") == 0


def test_dotted_line_dedup_is_idempotent():
    d = build()
    _g1, r1 = d.offboard("pm")               # deactivate leaf first
    assert _g1 == ["pm"] and r1 == 1
    gone2, r2 = d.offboard("pm")             # already inactive: no-op
    assert gone2 == [] and r2 == 0
    gone3, r3 = d.offboard("ceo")
    assert gone3 == ["ceo", "cto"]           # pm skipped: already inactive
    assert r3 == 2


def test_unknown_ids_tolerated():
    d = build()
    assert d.offboard("ghost") == ([], 0)
    assert d.hire("x", "X") is not None
    assert d.assign("x", "ghost") is False   # unknown report refused
    assert d.grant("ghost", "app") is False
    assert d.active_people() == ["auditor", "ceo", "cfo", "cto", "pm",
                                 "x"]


if __name__ == "__main__":
    test_offboards_closure_revokes_grants_once()
    test_dotted_line_dedup_is_idempotent()
    test_unknown_ids_tolerated()
    print("rec_28 ref harness: all assertions passed")

"""Reference harness for rec_36_bomsupply (BOM + suppliers). Exit 0."""
import sys

sys.path.insert(0, "/home/jac/repos/jac_llm_data/data/osp_lifts/combo")
from rec_36_bomsupply import BomCatalog


def build():
    b = BomCatalog()
    b.add_part("bike", lead=2)
    b.add_part("wheel", parent="bike", qty=2, lead=1)
    b.add_part("frame", parent="bike", qty=1, lead=3)
    b.add_part("spoke", parent="wheel", qty=12, lead=1)
    b.add_part("gear", parent="frame", qty=3, lead=2)
    return b


def test_structure_and_counts():
    b = build()
    assert sorted(b.parts) == ["bike", "frame", "gear", "spoke", "wheel"]
    # bike subtree: wheel, frame, spoke, gear = 4 components
    assert b.component_count("bike") == 4
    assert b.component_count("wheel") == 1
    try:
        b.add_part("wheel")
        raise AssertionError("expected duplicate error")
    except ValueError:
        pass
    try:
        b.add_part("x", parent="ghost")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass


def test_suppliers_inheritance():
    b = build()
    b.rate_supplier("spoke", "acme")
    b.rate_supplier("bike", "steelco")
    assert b.suppliers_for("spoke") == ["acme", "steelco"]  # inherited
    assert b.suppliers_for("bike") == ["steelco"]
    b.rate_supplier("spoke", "acme")   # idempotent
    assert b.suppliers_for("spoke") == ["acme", "steelco"]


def test_effective_lead():
    b = build()
    # spoke: leaf -> own lead 1
    assert b.effective_lead("spoke") == 1
    # wheel: 1 + max(spoke=1) = 2
    assert b.effective_lead("wheel") == 2
    # bike: 2 + max(wheel=2, frame=?) ; frame: 3+max(gear=2)=5
    assert b.effective_lead("bike") == 7


def test_discontinue_cascade_and_recount():
    b = build()
    doomed = b.discontinue("wheel")
    assert doomed == ["spoke", "wheel"]
    assert "wheel" not in b.parts and "spoke" not in b.parts
    assert b.component_count("bike") == 2      # frame + gear remain
    assert b.component_count("wheel") == 0     # gone
    # bike still 2 + frame chain (3+2)=7; wheel chain removal changed nothing
    assert b.effective_lead("bike") == 7
    try:
        b.discontinue("ghost")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass


test_structure_and_counts()
test_suppliers_inheritance()
test_effective_lead()
test_discontinue_cascade_and_recount()
print("rec_36 ref OK")
sys.exit(0)

"""Guard suite for rec_36_bomsupply."""
import from rec_36_bomsupply { BomCatalog }

def fresh() -> BomCatalog {
    b = BomCatalog();
    b.add_part("bike", lead=2);
    b.add_part("wheel", parent="bike", qty=2, lead=1);
    b.add_part("frame", parent="bike", qty=1, lead=3);
    b.add_part("spoke", parent="wheel", qty=12, lead=1);
    b.add_part("gear", parent="frame", qty=3, lead=2);
    return b;
}

test "structure and component counts" {
    b = fresh();
    assert sorted([b.by_pid[p].pid for p in b.by_pid]) == ["bike", "frame", "gear", "spoke", "wheel"];
    assert b.component_count("bike") == 4;
    assert b.component_count("wheel") == 1;
    threw_dup = False;
    try {
        b.add_part("wheel");
    } except ValueError as ex {
        threw_dup = True;
    }
    assert threw_dup;
}

test "supplier inheritance up the assembly chain" {
    b = fresh();
    b.rate_supplier("spoke", "acme");
    b.rate_supplier("bike", "steelco");
    assert b.suppliers_for("spoke") == ["acme", "steelco"];
    assert b.suppliers_for("bike") == ["steelco"];
    b.rate_supplier("spoke", "acme");  # idempotent
    assert b.suppliers_for("spoke") == ["acme", "steelco"];
}

test "effective lead longest chain" {
    b = fresh();
    assert b.effective_lead("spoke") == 1;
    assert b.effective_lead("wheel") == 2;
    assert b.effective_lead("frame") == 5;
    assert b.effective_lead("bike") == 7;
}

test "discontinue cascades and recomputes counts" {
    b = fresh();
    doomed = b.discontinue("wheel");
    assert doomed == ["spoke", "wheel"];
    assert len(doomed) == len(set(doomed));  # once-only
    assert "wheel" not in b.by_pid and "spoke" not in b.by_pid;
    assert b.component_count("bike") == 2;
    assert b.component_count("wheel") == 0;
    assert b.effective_lead("bike") == 7;  # frame chain unchanged
    threw_missing = False;
    try {
        b.discontinue("ghost");
    } except KeyError as ex {
        threw_missing = True;
    }
    assert threw_missing;
}

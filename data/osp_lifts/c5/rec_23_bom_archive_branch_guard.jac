"""Guard for rec_23_bom_archive_branch -- candidate OSP lift inlined verbatim
(same-prefix sibling imports are unreliable across jac's native seam), plus
behavioral tests: exclusive-branch archiving, shared-subassembly boundary
spared once then archived when requested directly, dangling/unknown
reference tolerance, idempotent re-archive, and an active-set invariant.
"""

node Part {
    has part_id: str;
    has name: str;
    has cost: float;
    has archived: bool = False;
    has uses: int = 0;      # how many assemblies reference this part
}

edge Assembles { }

"""Collect unarchived exclusive descendants below one part."""
walker ArchiveScan {
    has root_id: str;
    has to_archive: list[Part] = [];
    has seen: dict[str, bool] = {};

    can scan with Part entry {
        if here.part_id in self.seen {
            skip;           # diamond revisit / cycle policy: decide once,
        }                   # but keep sibling branches alive (no disengage)
        self.seen[here.part_id] = True;
        if here.archived {
            skip;           # already retired: stop descending, keep siblings
        }
        if here.part_id == self.root_id or here.uses <= 1 {
            self.to_archive.append(here);
            visit [->:Assembles:->];
        } else {
            # shared boundary: spare this subtree, keep sibling branches
            skip;
        }
    }
}

obj BomRegistry {
    has parts: dict[str, Part];

    def add_part(part_id: str, name: str, cost: float) -> Part {
        fresh = Part(part_id=part_id, name=name, cost=cost);
        self.parts[part_id] = fresh;
        return fresh;
    }

    """Attach *child_id* to *parent_id*'s bill of materials.

    Unknown child ids are tolerated: the write is refused, not raised.
    """
    def add_component(parent_id: str, child_id: str) -> bool {
        parent = self.parts.get(parent_id);
        child = self.parts.get(child_id);
        if child is None or parent is None {
            return False;
        }
        parent +>:Assembles:+> child;
        child.uses += 1;
        return True;
    }

    """Archive *part_id* plus exclusive descendants; returns change count."""
    def archive_branch(part_id: str) -> int {
        start = self.parts.get(part_id);
        if start is None {
            return 0;
        }
        # Phase COLLECT -- decide the retirement set without mutating.
        scan = start spawn ArchiveScan(root_id=part_id);
        changed = 0;
        # Phase APPLY -- flip state strictly after the walk finished.
        for p in scan.to_archive {
            if not p.archived {
                p.archived = True;
                changed += 1;
            }
        }
        return changed;
    }

    def active_parts -> list[str] {
        live = [pid for pid in self.parts.keys() if not self.parts[pid].archived];
        return sorted(live);
    }

    def is_archived(part_id: str) -> bool | None {
        p = self.parts.get(part_id);
        if p is None {
            return None;
        }
        return p.archived;
    }

    """How many assemblies reference this part (domain lookup)."""
    def usage_count(part_id: str) -> int {
        p = self.parts.get(part_id);
        if p is None {
            return 0;
        }
        return p.uses;
    }
}

"""Build a fresh deterministic BOM; creation order = fixture order."""
def load_graph(spec: list[tuple[str, str, float]],
               links: list[tuple[str, str]]) -> BomRegistry {
    bom = BomRegistry(parts={});
    for row in spec {
        _made = bom.add_part(row[0], row[1], row[2]);
    }
    for pair in links {
        _ok = bom.add_component(pair[0], pair[1]);
    }
    return bom;
}

test "archives_exclusive_branch_only" {
    bom = load_graph(
        spec=[
            ("bike", "Bike", 299.0), ("frame", "Frame", 80.0),
            ("wheels", "Wheels", 60.0), ("spokes", "Spokes", 12.0),
            ("spare_kit", "Spare Kit", 95.0), ("bell", "Bell", 5.0)
        ],
        links=[("bike", "frame"), ("bike", "wheels"),
               ("wheels", "spokes"), ("spare_kit", "wheels"),
               ("spare_kit", "bell")]
    );
    changed = bom.archive_branch("spare_kit");
    assert changed == 2;                        # spare_kit + bell
    assert bom.is_archived("spare_kit") is True;
    assert bom.is_archived("wheels") is False;  # still used by bike: spared
    assert bom.is_archived("spokes") is False;  # spared with its shared parent
    assert bom.active_parts() == ["bike", "frame", "spokes", "wheels"];
}

test "shared_part_archived_when_requested_directly" {
    bom = load_graph(
        spec=[
            ("bike", "Bike", 299.0), ("wheels", "Wheels", 60.0),
            ("spokes", "Spokes", 12.0), ("spare_kit", "Spare Kit", 95.0)
        ],
        links=[("bike", "wheels"), ("wheels", "spokes"),
               ("spare_kit", "wheels")]
    );
    assert bom.usage_count("wheels") == 2;
    assert bom.archive_branch("wheels") == 2;   # wheels + exclusive spokes
    assert bom.is_archived("spokes") is True;
    assert bom.is_archived("bike") is False;
    assert bom.archive_branch("wheels") == 0;   # idempotent re-archive
    assert bom.archive_branch("ghost") == 0;    # unknown id tolerated
}

test "dangling_component_ref_never_enters_graph" {
    bom = load_graph(
        spec=[("bike", "Bike", 299.0), ("frame", "Frame", 80.0)],
        links=[("bike", "frame")]
    );
    ok = bom.add_component("bike", "ghost_part");
    assert ok is False;                          # refused write, no raise
    assert bom.archive_branch("bike") == 2;      # bike + frame only
    assert sorted(bom.active_parts()) == [];
}

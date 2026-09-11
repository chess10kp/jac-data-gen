"""Idiomatic OSP lift: manufacturing BOM branch archiving (category C5).

Two-phase mutation protocol (OSP_IDIOMIZE_TASK.md §5.5):

Phase COLLECT -- `ArchiveScan` gathers the parts to retire into typed `has`
fields. The seen-guard on part ids is the once-only guard for shared
subassemblies AND the explicit cycle policy (no built-in dedup in 0.36.1):
a revisited id disengages. A part referenced by more than one assembly
(`uses > 1`) is a shared boundary -- it is spared with its whole subtree
(`skip;` keeps sibling branches alive) unless it is the requested root.
Unknown component references never enter the graph, mirroring the source's
tolerant registry writes.

Phase APPLY -- outside any walk, the façade flips `archived` on the
collected set; the source's registry-scan `usage_count` dies: the count now
lives on the node and is maintained when assemblies are attached.
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

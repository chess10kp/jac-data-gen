"""Manufacturing BOM registry with bulk branch archiving.

Parts form an assembly graph: ``components`` lists direct children and a
subassembly may legitimately appear under several parents (standard kits,
fastener sets). ``archive_branch`` marks a part and its EXCLUSIVE
descendants archived; a part referenced from any other branch stays active
together with everything below it. Usage counts are recomputed by scanning
the registry, unknown component ids are skipped silently, and re-archiving
an archived branch is a no-op that reports zero changes.
"""
class Part {
    has part_id: str;
    has name: str;
    has cost: float;
    has archived: bool = False;
    def init(self: Part, part_id: str, name: str, cost: float) -> object {
        self.part_id = part_id;
        self.name = name;
        self.cost = cost;
        self.components = [];
        self.archived = False;
    }
}
class BomRegistry {
    has parts: dict[str, Part];
    def init(self: BomRegistry) -> object {
        self.parts = {};
    }
    def add_part(self: BomRegistry, part_id: str, name: str, cost: float) -> object {
        self.parts[part_id] = Part(part_id, name, cost);
        return self.parts[part_id];
    }
    def add_component(self: BomRegistry, parent_id: str, child_id: str) -> object {
        if (child_id not in self.parts) {
            return False;
        }
        self.parts[parent_id].components.append(child_id);
        return True;
    }
    def usage_count(self: BomRegistry, part_id: str) -> object {
        n = 0;
        for p in self.parts.values() {
            if (part_id in p.components) {
                n += 1;
            }
        }
        return n;
    }
    def _collect(
        self: BomRegistry, part_id: str, visited: set[str], to_archive: list[Part], root_id: str
    ) -> object {
        if ((part_id in visited) or (part_id not in self.parts)) {
            return;
        }
        visited.add(part_id);
        part = self.parts[part_id];
        if part.archived {
            return;
        }
        if ((part_id == root_id) or (self.usage_count(part_id) <= 1)) {
            to_archive.append(part);
            child_ids = part.components as list[str];
            for child_id in child_ids {
                self._collect(child_id, visited, to_archive, root_id);
            }
        }
    }
    def archive_branch(self: BomRegistry, part_id: str) -> object {
        if (part_id not in self.parts) {
            return 0;
        }
        to_archive: list[Part] = [];
        self._collect(part_id, set(), to_archive, part_id);
        changed = 0;
        for p in to_archive as list[Part] {
            if not p.archived {
                p.archived = True;
                changed += 1;
            }
        }
        return changed;
    }

    def active_parts(self: BomRegistry) -> object {
        return sorted(
            pid
            for (pid, p) in self.parts.items()
            if not p.archived
        );
    }
    def is_archived(self: BomRegistry, part_id: str) -> object {
        p = self.parts.get(part_id);
        return p.archived if p else None;
    }
}


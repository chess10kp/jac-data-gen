"""Manufacturing BOM registry with bulk branch archiving.

Parts form an assembly graph: ``components`` lists direct children and a
subassembly may legitimately appear under several parents (standard kits,
fastener sets). ``archive_branch`` marks a part and its EXCLUSIVE
descendants archived; a part referenced from any other branch stays active
together with everything below it. Usage counts are recomputed by scanning
the registry, unknown component ids are skipped silently, and re-archiving
an archived branch is a no-op that reports zero changes.
"""


class Part:
    def __init__(self, part_id, name, cost):
        self.part_id = part_id
        self.name = name
        self.cost = cost
        self.components = []     # child part_ids; a child may repeat across parents
        self.archived = False


class BomRegistry:
    def __init__(self):
        self.parts = {}          # part_id -> Part

    def add_part(self, part_id, name, cost):
        self.parts[part_id] = Part(part_id, name, cost)
        return self.parts[part_id]

    def add_component(self, parent_id, child_id):
        """Attach *child_id* to *parent_id*'s bill of materials."""
        if child_id not in self.parts:    # tolerate unknown refs
            return False
        self.parts[parent_id].components.append(child_id)
        return True

    def usage_count(self, part_id):
        """How many assemblies reference this part (registry scan)."""
        n = 0
        for p in self.parts.values():
            if part_id in p.components:
                n += 1
        return n

    def _collect(self, part_id, visited, to_archive, root_id):
        """Recursive descent collecting unarchived exclusive descendants."""
        if part_id in visited or part_id not in self.parts:
            return
        visited.add(part_id)
        part = self.parts[part_id]
        if part.archived:
            return                      # already retired: stop descending
        if part_id == root_id or self.usage_count(part_id) <= 1:
            # the requested root is always taken; others must be exclusive
            to_archive.append(part)
            for child_id in part.components:
                self._collect(child_id, visited, to_archive, root_id)
        # shared non-root parts are spared with their whole subtree

    def archive_branch(self, part_id):
        """Archive *part_id* plus exclusive descendants.

        Returns how many parts changed state. Shared subassemblies reached
        below the root are left active; unknown ids report zero.
        """
        if part_id not in self.parts:
            return 0
        to_archive = []
        self._collect(part_id, set(), to_archive, part_id)
        changed = 0
        for p in to_archive:
            if not p.archived:
                p.archived = True
                changed += 1
        return changed

    def active_parts(self):
        return sorted(pid for pid, p in self.parts.items() if not p.archived)

    def is_archived(self, part_id):
        p = self.parts.get(part_id)
        return p.archived if p else None

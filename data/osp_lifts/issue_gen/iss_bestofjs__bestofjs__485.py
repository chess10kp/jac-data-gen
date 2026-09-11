"""Tag taxonomy: subset hierarchy, effective membership and cleanup sweeps.

Before-code synthesized from bestofjs/bestofjs#485: a tag may declare one
parent meaning "every project with this tag is by definition tagged with
the parent" (nextjs -> react). Effective membership therefore closes over
ancestor chains, while the catalog still stores redundant direct tags --
a project tagged both ``nextjs`` and ``react`` does not need the ``react``
row anymore. Reparenting must reject cycles at write time, and after any
reparent a cleanup sweep drops now-redundant direct tags per project,
decrementing each tag's stored usage count exactly once. Parent pointers
for tags, an id-keyed membership map for projects, and hand-rolled walks
everywhere.
"""


class CycleError(ValueError):
    """Setting that parent would create a cycle."""


class TagTaxonomy:
    def __init__(self):
        self.parent_of = {}     # tag -> parent | None
        self.facet_of = {}      # tag -> "ecosystem" | "category" | ...
        self.tags_of = {}       # project -> set of directly stored tags
        self.usage = {}         # tag -> number of projects storing it

    def add_tag(self, name, parent=None, facet=None):
        if parent is not None and parent not in self.parent_of:
            raise KeyError("unknown parent tag")
        if parent == name:
            raise CycleError("self parent")
        self.parent_of[name] = parent
        self.facet_of[name] = facet
        self.usage.setdefault(name, 0)

    def _ancestors(self, tag):
        chain = []
        seen = {tag}
        cur = self.parent_of.get(tag)
        while cur is not None:
            if cur in seen:
                break  # tolerate corrupt cycles on read paths
            seen.add(cur)
            chain.append(cur)
            cur = self.parent_of.get(cur)
        return chain

    def _descendants(self, tag):
        out = []
        stack = [tag]
        seen = set()
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            if cur != tag:
                out.append(cur)
            for t, p in self.parent_of.items():
                if p == cur:
                    stack.append(t)
        return out

    def set_parent(self, tag, new_parent):
        """Write-time cycle guard: refuse if new_parent is a descendant."""
        if new_parent not in self.parent_of:
            raise KeyError("unknown parent tag")
        if new_parent == tag or new_parent in self._descendants(tag):
            raise CycleError("would create a cycle")
        old = self.parent_of[tag]
        changed = old != new_parent
        self.parent_of[tag] = new_parent
        return changed

    def tag_project(self, project, tag):
        if tag not in self.parent_of:
            raise KeyError("unknown tag")
        projs = self.tags_of.setdefault(project, set())
        if tag not in projs:
            projs.add(tag)
            self.usage[tag] += 1

    def effective_tags(self, project):
        """Direct tags plus every ancestor they imply (closure)."""
        eff = set(self.tags_of.get(project, ()))
        for t in self.tags_of.get(project, ()):
            eff.update(self._ancestors(t))
        return sorted(eff)

    def projects_with(self, tag):
        """Projects effectively carrying ``tag`` via closure."""
        return sorted(
            p for p in self.tags_of if tag in self.effective_tags(p)
        )

    def _redundant_for(self, project):
        """Direct tags already implied by another DIRECT tag below them."""
        direct = self.tags_of.get(project, set())
        red = []
        for t in direct:
            for other in direct:
                if other != t and t in self._ancestors(other):
                    red.append(t)
                    break
        return sorted(red)

    def cleanup_project(self, project):
        """Drop redundant direct rows; decrement each count exactly once."""
        red = self._redundant_for(project)
        for t in red:  # phase 2: apply outside detection
            self.tags_of[project].discard(t)
            self.usage[t] -= 1
        return red

    def cleanup_after_reparent(self):
        """Sweep every project; returns {project: [removed tags]}."""
        report = {}
        for p in sorted(self.tags_of.keys()):
            dropped = self.cleanup_project(p)
            if dropped:
                report[p] = dropped
        return report

    def rollup_count(self, tag):
        """Projects carrying ``tag`` or anything beneath it (effective)."""
        fam = set(self._descendants(tag)) | {tag}
        n = 0
        for p in self.tags_of:
            if set(self.effective_tags(p)) & fam:
                n += 1
        return n

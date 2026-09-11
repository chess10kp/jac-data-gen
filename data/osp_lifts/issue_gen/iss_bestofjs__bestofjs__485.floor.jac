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
"""Setting that parent would create a cycle."""
class CycleError(ValueError) {}
class TagTaxonomy {
    def init(self: TagTaxonomy)  -> Any {
        self.parent_of = {};
        self.facet_of = {};
        self.tags_of = {};
        self.usage = {};
    }
    def add_tag(
        self: TagTaxonomy, name: Any, parent: Any = None, facet: Any = None
    ) {
        if ((parent is not None) and (parent not in self.parent_of)) {
            raise KeyError("unknown parent tag");
        }
        if (parent == name) {
            raise CycleError("self parent");
        }
        self.parent_of[name] = parent;
        self.facet_of[name] = facet;
        self.usage.setdefault(name, 0);
    }
    def _ancestors(self: TagTaxonomy, tag: Any)  -> Any {
        chain = [];
        seen = {tag};
        cur = self.parent_of.get(tag);
        while (cur is not None) {
            if (cur in seen) {
                break;
            }
            seen.add(cur);
            chain.append(cur);
            cur = self.parent_of.get(cur);
        }
        return chain;
    }
    def _descendants(self: TagTaxonomy, tag: Any)  -> Any {
        out = [];
        stack = [tag];
        seen = `set();
        while stack {
            cur = stack.pop();
            if (cur in seen) {
                continue;
            }
            seen.add(cur);
            if (cur != tag) {
                out.append(cur);
            }
            for (t, p) in self.parent_of.items() {
                if (p == cur) {
                    stack.append(t);
                }
            }
        }
        return out;
    }
    """Write-time cycle guard: refuse if new_parent is a descendant."""
    def set_parent(self: TagTaxonomy, tag: Any, new_parent: Any)  -> Any {
        if (new_parent not in self.parent_of) {
            raise KeyError("unknown parent tag");
        }
        if ((new_parent == tag) or (new_parent in self._descendants(tag))) {
            raise CycleError("would create a cycle");
        }
        old = self.parent_of[tag];
        changed = old != new_parent;
        self.parent_of[tag] = new_parent;
        return changed;
    }
    def tag_project(self: TagTaxonomy, project: Any, tag: Any)  -> Any {
        if (tag not in self.parent_of) {
            raise KeyError("unknown tag");
        }
        projs = self.tags_of.setdefault(project, `set());
        if (tag not in projs) {
            projs.add(tag);
            self.usage[tag] += 1;
        }
    }
    """Direct tags plus every ancestor they imply (closure)."""
    def effective_tags(self: TagTaxonomy, project: Any)  -> Any {
        eff = `set(self.tags_of.get(project, ()));
        for t in list(self.tags_of.get(project, ())) {
            eff.update(list(self._ancestors(t)));
        }
        return sorted(eff);
    }
    """Projects effectively carrying ``tag`` via closure."""
    def projects_with(self: TagTaxonomy, tag: Any)  -> Any {
        return sorted(
            p
            for p in self.tags_of
            if (tag in self.effective_tags(p))
        );
    }
    """Direct tags already implied by another DIRECT tag below them."""
    def _redundant_for(self: TagTaxonomy, project: Any)  -> Any {
        direct = self.tags_of.get(project, `set());
        red = [];
        for t in list(direct) {
            for other in list(direct) {
                if ((other != t) and (t in self._ancestors(other))) {
                    red.append(t);
                    break;
                }
            }
        }
        return sorted(red);
    }
    """Drop redundant direct rows; decrement each count exactly once."""
    def cleanup_project(self: TagTaxonomy, project: Any)  -> Any {
        red = self._redundant_for(project);
        for t in red {
            self.tags_of[project].discard(t);
            self.usage[t] -= 1;
        }
        return red;
    }
    """Sweep every project; returns {project: [removed tags]}."""
    def cleanup_after_reparent(self: TagTaxonomy)  -> Any {
        `report = {};
        for p in sorted(self.tags_of.keys()) {
            dropped = self.cleanup_project(p);
            if dropped {
                `report[p] = dropped;
            }
        }
        return `report;
    }
    """Projects carrying ``tag`` or anything beneath it (effective)."""
    def rollup_count(self: TagTaxonomy, tag: Any)  -> Any {
        fam = `set(self._descendants(tag)) | {tag};
        n = 0;
        for p in self.tags_of {
            if (`set(self.effective_tags(p)) & fam) {
                n += 1;
            }
        }
        return n;
    }
}


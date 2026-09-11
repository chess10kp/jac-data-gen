"""Competency Criteria Group removal with progress protection.

Before-code synthesized from openedx/openedx-core#675: a competency's
mastery rule is an unbounded tree of criterion groups holding leaf
criteria; removal must take the WHOLE subtree. Hard delete is allowed
only while NO learner status row exists anywhere beneath the target --
once any exists the branch becomes archive-only. Authoring caps nesting
at depth 3. Groups keep parent pointers and children adjacency maps;
learner progress is a many-to-many link map walked when deciding fate.
Criteria keep their insertion order per group -- mastery rules evaluate
in that order, so it is observable domain data, not an implementation
detail.
"""
with entry {
    MAX_DEPTH = 3;
}
"""Authoring forbids nesting deeper than three group levels."""
class DepthError(ValueError) {}
class CompetencyTree {
    def init(self: CompetencyTree)  -> Any {
        self.kind_of = {};
        self.parent_of = {};
        self.children_of = {};
        self.archived = `set();
        self.progress = {};
    }
    def _depth_of(self: CompetencyTree, name: Any)  -> int {
        depth = 0;
        seen = {name};
        cur = self.parent_of.get(name);
        while (cur is not None) {
            if (cur in seen) {
                break;
            }
            seen.add(cur);
            depth += 1;
            cur = self.parent_of.get(cur);
        }
        return depth;
    }
    """Groups nest; the backend enforces the depth cap."""
    def add_group(self: CompetencyTree, name: Any, parent: Any = None)  -> Any {
        if ((parent is not None) and (parent not in self.parent_of)) {
            raise KeyError("unknown parent");
        }
        if ((parent is not None) and (self.kind_of[parent] != "group")) {
            raise ValueError("criteria are leaves");
        }
        if ((parent is not None) and ((self._depth_of(parent) + 1) >= int(MAX_DEPTH))) {
            raise DepthError(("nesting exceeds depth %d" % MAX_DEPTH));
        }
        self.kind_of[name] = "group";
        self.parent_of[name] = parent;
        if (parent is not None) {
            self.children_of.setdefault(parent, []).append(name);
        }
        self.children_of.setdefault(name, []);
        return True;
    }
    def add_criterion(self: CompetencyTree, name: Any, parent_group: Any)  -> Any {
        if (parent_group not in self.kind_of) {
            raise KeyError("unknown parent group");
        }
        if (self.kind_of[parent_group] != "group") {
            raise ValueError("criteria are leaves");
        }
        self.kind_of[name] = "criterion";
        self.parent_of[name] = parent_group;
        self.children_of.setdefault(parent_group, []).append(name);
        return True;
    }
    def record_progress(self: CompetencyTree, learner: Any, criterion: Any)  -> Any {
        if (self.kind_of.get(criterion) != "criterion") {
            raise KeyError("unknown criterion");
        }
        self.progress.setdefault(learner, `set()).add(criterion);
    }
    def _subtree(self: CompetencyTree, `root: Any)  -> Any {
        out = [];
        stack = [`root];
        seen = `set();
        while stack {
            cur = stack.pop();
            if (cur in seen) {
                continue;
            }
            seen.add(cur);
            out.append(cur);
            stack.extend(self.children_of.get(cur, []));
        }
        return out;
    }
    """Cross-link reachability: learners touching any leaf below."""
    def progress_in_subtree(self: CompetencyTree, `root: Any)  -> Any {
        nodes = `set(self._subtree(`root));
        learners = [];
        for (learner, crits) in self.progress.items() {
            if (crits & nodes) {
                learners.append(learner);
            }
        }
        return sorted(learners);
    }
    """Remove the whole subtree; archive-only once progress exists.

        Two-phase: collect the closure and probe progress first, then
        apply either archival flips or hard removal. Returns a tuple of
        (fate, affected_node_names_sorted).
        """
    def remove_group(self: CompetencyTree, `root: Any)  -> Any {
        if (self.kind_of.get(`root) != "group") {
            raise KeyError("unknown group");
        }
        doomed = sorted(list(self._subtree(root)));
        touched = self.progress_in_subtree(`root);
        if touched {
            for n in doomed {
                self.archived.add(n);
            }
            return ("archived", doomed);
        }
        parent = self.parent_of.get(`root);
        if (parent is not None) {
            self.children_of[parent] = [
                c
                for c in self.children_of.get(parent, [])
                if (c != `root)
            ];
        }
        for n in doomed {
            self.kind_of.pop(n, None);
            self.parent_of.pop(n, None);
            self.children_of.pop(n, None);
            self.archived.discard(n);
        }
        return ("deleted", doomed);
    }

    """Insertion order within this group only (evaluation order)."""
    def list_criteria_ordered(self: CompetencyTree, group: Any)  -> Any {
        out = [];
        for child in list(self.children_of.get(group, [])) {
            if (
                (self.kind_of.get(child) == "criterion")
                and (child not in self.archived)
            ) {
                out.append(child);
            }
        }
        return out;
    }
    def live_nodes(self: CompetencyTree)  -> Any {
        return sorted(
            n
            for n in self.kind_of
            if (n not in self.archived)
        );
    }
}


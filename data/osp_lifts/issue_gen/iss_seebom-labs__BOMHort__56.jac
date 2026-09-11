"""seebom-labs/BOMHort#56 — idiomatic OSP dependency tree (SBOM detail view)."""

node Component {
    has id: str,
        name: str;
}

edge Depends {}

obj DependencyService {
    has root_anchor: object = root;

    def add_component(id: str, name: str) -> Component {
        c = Component(id=id, name=name);
        self.root_anchor ++> c;
        return c;
    }

    def link_dependency(parent: Component, child: Component) -> None {
        parent +>:Depends:+> child;
    }

    def find_by_id(target_id: str) -> Component | None {
        for c in [self.root_anchor-->[?:Component]] {
            if c.id == target_id {
                return c;
            }
        }
        return None;
    }

    def direct_dependencies(component_id: str) -> list[str] {
        parent = self.find_by_id(component_id);
        if parent is None {
            raise KeyError("unknown component");
        }
        kids = [parent-->[?:Component]];
        return sorted([k.id for k in kids]);
    }

    def dependency_closure(component_id: str) -> list[str] {
        parent = self.find_by_id(component_id);
        if parent is None {
            raise KeyError("unknown component");
        }
        w = self.root_anchor spawn ClosureWalker(start=parent);
        return sorted(w.ids);
    }

    def has_cycle() -> bool {
        w = self.root_anchor spawn CycleWalker();
        return w.found;
    }

    def tree_rows(component_id: str) -> list[tuple[int, str, str]] {
        parent = self.find_by_id(component_id);
        if parent is None {
            raise KeyError("unknown component");
        }
        w = self.root_anchor spawn TreeRowsWalker(start=parent);
        return w.rows;
    }

    def remove_component(component_id: str) -> None {
        target = self.find_by_id(component_id);
        if target is None {
            raise KeyError("unknown component");
        }
        w = self.root_anchor spawn ClosureWalker(start=target);
        drop_ids = set(w.ids);
        for c in [self.root_anchor-->[?:Component]] {
            if c.id in drop_ids {
                del c;
            }
        }
    }
}

walker ClosureWalker {
    has start: Component,
        ids: list[str] = [],
        claimed: dict = {};

    can begin with Root entry {
        visit [self.start];
    }

    can on_component with Component entry {
        key = here.jid;
        if self.claimed.get(key) {
            skip;
        }
        self.claimed[key] = True;
        self.ids.append(here.id);
        visit [-->][?:Component];
    }
}

walker CycleWalker {
    has found: bool = False,
        stack: list[str] = [],
        on_stack: dict = {};

    can begin with Root entry {
        visit [-->][?:Component];
    }

    can on_component with Component entry {
        jid = here.jid;
        if self.on_stack.get(jid) {
            self.found = True;
            disengage;
        }
        self.on_stack[jid] = True;
        self.stack.append(jid);
        visit [-->][?:Component];
    }

    can unwind with Component exit {
        top = self.stack.pop();
        self.on_stack.pop(top, None);
    }
}

walker TreeRowsWalker {
    has start: Component,
        rows: list[tuple[int, str, str]] = [],
        claimed: dict = {},
        depth: int = 0;

    can begin with Root entry {
        visit [self.start];
    }

    can on_component with Component entry {
        key = here.jid;
        if self.claimed.get(key) {
            skip;
        }
        self.claimed[key] = True;
        self.rows.append((self.depth, here.id, here.name));
        self.depth += 1;
        visit [-->][?:Component];
    }

    can leave with Component exit {
        self.depth -= 1;
    }
}

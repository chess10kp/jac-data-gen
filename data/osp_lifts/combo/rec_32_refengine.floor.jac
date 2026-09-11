"""IDE-like refactor engine.

Scopes nest into a tree (module -> class -> function ...). Scopes define
symbols and contain references to symbols defined elsewhere. Renames must
respect nesting resolution: a name resolves to the nearest enclosing scope
that defines it.

Hand-rolled machinery:
- parent/children pointers with chain walking and subtree descent (C1)
- defs/refs name-indexed adjacency with stack walks (C2)
"""
class Scope {
    def init(self: Scope, sid: Any, parent: Any = None) -> object {
        self.sid = sid;
        self.parent = parent;
        self.children = [];
        self.symbols = [];
    }
}
class RefactorEngine {
    def init(self: RefactorEngine) -> object {
        self.scopes = {};
        self.defs = {};
        self.refs = {};
    }
    def add_scope(self: RefactorEngine, sid: Any, parent: Any = None) -> object {
        if (sid in self.scopes) {
            raise ValueError("duplicate scope");
        }
        p = self.scopes[parent] if (parent is not None) else None;
        s = Scope(sid, p);
        if (p is not None) {
            p.children.append(s);
        }
        self.scopes[sid] = s;
        return sid;
    }
    def define(self: RefactorEngine, sid: Any, name: Any) -> object {
        s = self.scopes[sid];
        s.symbols.append(name);
        self.defs.setdefault(name, []).append(sid);
    }
    def add_reference(self: RefactorEngine, sid: Any, name: Any) -> object {
        self.refs.setdefault(name, `set()).add(sid);
    }
    """Nearest enclosing definition site for name starting at sid."""
    def resolve(self: RefactorEngine, sid: Any, name: Any) -> object {
        cur = self.scopes[sid];
        while (cur is not None) {
            if (name in cur.symbols) {
                return cur.sid;
            }
            cur = cur.parent;
        }
        return None;
    }
    """All referencing scopes inside the subtree rooted at root_sid."""
    def references_within(self: RefactorEngine, root_sid: Any, name: Any) -> object {
        out = [];
        seen = `set();
        stack = [root_sid];
        while stack {
            sid = stack.pop();
            if (sid in seen) {
                continue;
            }
            seen.add(sid);
            if (sid in self.refs.get(name, `set())) {
                out.append(sid);
            }
            for c in self.scopes[sid].children {
                cs = c as Scope;
                stack.append(cs.sid as str);
            }
        }
        return sorted(out);
    }
    """Rename symbol old to new everywhere. Returns number of affected
        reference sites. Fails if new is already defined."""
    def rename(self: RefactorEngine, old: Any, new: Any) -> object {
        if (old == new) {
            return 0;
        }
        if (new in self.defs) {
            raise ValueError("name collision");
        }
        if (old not in self.defs) {
            raise KeyError(old);
        }
        affected = sorted(self.refs.get(old, `set()));
        defining = `list(self.defs.pop(old));
        self.defs[new] = defining;
        for sid in defining {
            s = self.scopes[sid];
            s.symbols = [new if (n == old) else n for n in s.symbols];
        }
        self.refs[new] = self.refs.pop(old);
        return len(affected);
    }

    def definitions(self: RefactorEngine, name: Any) -> object {
        return sorted(self.defs.get(name, []));
    }
}


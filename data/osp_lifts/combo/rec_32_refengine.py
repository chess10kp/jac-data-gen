"""IDE-like refactor engine.

Scopes nest into a tree (module -> class -> function ...). Scopes define
symbols and contain references to symbols defined elsewhere. Renames must
respect nesting resolution: a name resolves to the nearest enclosing scope
that defines it.

Hand-rolled machinery:
- parent/children pointers with chain walking and subtree descent (C1)
- defs/refs name-indexed adjacency with stack walks (C2)
"""


class Scope:
    def __init__(self, sid, parent=None):
        self.sid = sid
        self.parent = parent
        self.children = []
        self.symbols = []


class RefactorEngine:
    def __init__(self):
        self.scopes = {}  # sid -> Scope
        self.defs = {}    # name -> list of defining sids
        self.refs = {}    # name -> set of referencing sids

    def add_scope(self, sid, parent=None):
        if sid in self.scopes:
            raise ValueError("duplicate scope " + sid)
        p = self.scopes[parent] if parent is not None else None
        s = Scope(sid, p)
        if p is not None:
            p.children.append(s)
        self.scopes[sid] = s
        return sid

    def define(self, sid, name):
        s = self.scopes[sid]
        s.symbols.append(name)
        self.defs.setdefault(name, []).append(sid)

    def add_reference(self, sid, name):
        self.refs.setdefault(name, set()).add(sid)

    def resolve(self, sid, name):
        """Nearest enclosing definition site for name starting at sid."""
        cur = self.scopes[sid]
        while cur is not None:
            if name in cur.symbols:
                return cur.sid
            cur = cur.parent
        return None

    def references_within(self, root_sid, name):
        """All referencing scopes inside the subtree rooted at root_sid."""
        out = []
        seen = set()
        stack = [root_sid]
        while stack:
            sid = stack.pop()
            if sid in seen:
                continue
            seen.add(sid)
            if sid in self.refs.get(name, set()):
                out.append(sid)
            stack.extend(c.sid for c in self.scopes[sid].children)
        return sorted(out)

    def rename(self, old, new):
        """Rename symbol old to new everywhere. Returns number of affected
        reference sites. Fails if new is already defined."""
        if old == new:
            return 0
        if new in self.defs:
            raise ValueError("name collision on " + new)
        if old not in self.defs:
            raise KeyError(old)
        affected = sorted(self.refs.get(old, set()))
        defining = list(self.defs.pop(old))
        self.defs[new] = defining
        for sid in defining:
            s = self.scopes[sid]
            s.symbols = [new if n == old else n for n in s.symbols]
        self.refs[new] = self.refs.pop(old)
        return len(affected)

    def definitions(self, name):
        return sorted(self.defs.get(name, []))

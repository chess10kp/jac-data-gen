"""IDE-like refactor engine, lifted to OSP.

Scopes are nodes nested via Nest edges; symbols are nodes linked by Defines
(definition site) and References (usage cross-link). Walkers replace the
parent-chain resolution loop and the subtree stack walk. Cycle policy: the
scope tree is acyclic by construction; subtree walks still carry a guard set
because shared references re-enter scopes.
"""
node Scope {
    has sid: str;
}

node Symbol {
    has name: str;
}

"""Scope nesting: parent +>:Nest:+> child."""
edge Nest {}

"""Definition site: scope defines symbol."""
edge Defines {}

"""Usage cross-link: scope references symbol."""
edge References {}

walker SubtreeRefs {
    """Stack-equivalent descent over Nest edges collecting scopes that
    reference the target symbol. Guard set handles shared references."""
    has target: Symbol;
    has hits: list[str] = [];
    has claimed: dict[str, bool] = {};

    can step with Scope entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        uses: list[Symbol] = [here ->:References:->];
        if self.target in uses {
            self.hits.append(here.sid);
        }
        visit [->:Nest:->];
    }
}

walker ChainResolver {
    """Ascend Nest edges to the nearest scope defining the target name.
    The chain is linear, so first hit wins and disengage ends the walk."""
    has name: str;
    has found: str | None = None;

    can step with Scope entry {
        defined: list[Symbol] = [here ->:Defines:->];
        if any(s.name == self.name for s in defined) {
            self.found = here.sid;
            disengage;
        }
        visit [here <-:Nest:<-] else { disengage; }
    }
}

obj RefactorEngine {
    """Compatibility facade. Scope ids and symbol names are the public API
    currency; by_id/by_name are domain lookup state, not traversal state."""
    has by_id: dict[str, Scope] = {};
    has by_name: dict[str, Symbol] = {};

    def add_scope(sid: str, parent: str | None = None) -> str {
        if sid in self.by_id {
            raise ValueError("duplicate scope " + sid);
        }
        s := Scope(sid=sid);
        if parent is not None {
            p = self.by_id[parent];
            p +>:Nest:+> s;
        }
        self.by_id[sid] = s;
        return sid;
    }

    def define(sid: str, name: str) -> None {
        sym = self._intern(name);
        self.by_id[sid] +>:Defines:+> sym;
    }

    def add_reference(sid: str, name: str) -> None {
        sym = self._intern(name);
        self.by_id[sid] +>:References:+> sym;
    }

    def resolve(sid: str, name: str) -> str | None {
        w: ChainResolver = self.by_id[sid] spawn ChainResolver(name=name);
        return w.found;
    }

    def references_within(root_sid: str, name: str) -> list[str] {
        sym = self.by_name.get(name);
        if sym is None {
            return [];
        }
        w: SubtreeRefs = self.by_id[root_sid] spawn SubtreeRefs(target=sym);
        return sorted(w.hits);
    }

    """Two-phase rename: walkers collect definition sites and reference
    sites, then edges are rewired outside any walk."""
    def rename(old: str, new: str) -> int {
        if old == new {
            return 0;
        }
        old_sym = self.by_name.get(old);
        if old_sym is None {
            raise KeyError(old);
        }
        if new in self.by_name {
            raise ValueError("name collision on " + new);
        }
        new_sym = Symbol(name=new);
        definers: list[Scope] = [old_sym <-:Defines:<-];
        users: list[Scope] = [old_sym <-:References:<-];
        for s in definers {
            s del ->:Defines:-> old_sym;
            s +>:Defines:+> new_sym;
        }
        for s in users {
            s del ->:References:-> old_sym;
            s +>:References:+> new_sym;
        }
        self.by_name.pop(old);
        self.by_name[new] = new_sym;
        return len(users);
    }

    def definitions(name: str) -> list[str] {
        sym = self.by_name.get(name);
        if sym is None {
            return [];
        }
        sites: list[Scope] = [sym <-:Defines:<-];
        return sorted(s.sid for s in sites);
    }

    def _intern(name: str) -> Symbol {
        sym = self.by_name.get(name);
        if sym is None {
            sym = Symbol(name=name);
            self.by_name[name] = sym;
        }
        return sym;
    }
}

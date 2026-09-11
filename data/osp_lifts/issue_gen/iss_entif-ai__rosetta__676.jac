"""entif-ai/rosetta#676 — DocID registry lineage (OSP)."""

node Doc {
    has doc_id: str;
}

edge Supersedes {}

obj DocRegistry {
    has _root: Root;

    def init() {
        self._root = root;
    }

    def register(doc_id: str) -> None {
        if self._find(doc_id) is not None {
            raise ValueError(f"duplicate doc id: {doc_id}");
        }
        self._root ++> Doc(doc_id=doc_id);
    }

    def supersedes(new_id: str, old_id: str) -> None {
        n = self._find(new_id);
        o = self._find(old_id);
        if n is None or o is None {
            raise KeyError("unknown doc id");
        }
        n +>:Supersedes:+> o;
    }

    def lineage(doc_id: str) -> list[str] {
        n = self._find(doc_id);
        if n is None {
            return [];
        }
        w = self._root spawn LineageWalker(start_id=doc_id);
        return sorted(w.seen);
    }

    def find_cycle() -> list[str] {
        w = self._root spawn CycleFinder();
        return w.cycle if w.cycle else [];
    }

    def _find(doc_id: str) -> Doc | None {
        for d in [self._root-->[?:Doc]] {
            if d.doc_id == doc_id {
                return d;
            }
        }
        return None;
    }
}

walker LineageWalker {
    has start_id: str;
    has seen: list[str] = [];
    has claims: dict[str, bool] = {};

    can start with Root entry {
        for d in [-->][?:Doc] {
            if d.doc_id == self.start_id {
                visit [d];
            }
        }
    }

    can walk with Doc entry {
        did = here.doc_id;
        if did in self.claims {
            skip;
        }
        self.claims[did] = True;
        self.seen.append(did);
        visit [here->:Supersedes:->];
    }
}

walker CycleFinder {
    has cycle: list[str] = [];
    has on_stack: dict[str, bool] = {};
    has stack_ids: list[str] = [];

    can start with Root entry {
        visit [-->][?:Doc];
    }

    can walk with Doc entry {
        if self.cycle {
            skip;
        }
        did = here.doc_id;
        if did in self.on_stack and self.on_stack[did] {
            i = 0;
            for (idx, x) in enumerate(self.stack_ids) {
                if x == did {
                    i = idx;
                    break;
                }
            }
            self.cycle = self.stack_ids[i:] + [did];
            skip;
        }
        self.on_stack[did] = True;
        self.stack_ids = self.stack_ids + [did];
        visit [here->:Supersedes:->];
        self.stack_ids = self.stack_ids[:-1];
        self.on_stack[did] = False;
    }
}

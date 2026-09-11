"""OSP lift for ntntlang/ntnt#183 — cycle-safe lexical scopes."""

node Scope {
    has name: str;
}

edge Owns {}

walker OwnsWalker {
    has safe: bool = True;
    has color: dict[str, int] = {};
    has start: str = "";

    can begin with Root entry {
        for s in [-->][?:Scope] {
            if s.name == self.start {
                visit [s];
            }
        }
    }

    can step with Scope entry {
        if here.name in self.color and self.color[here.name] == 1 {
            self.safe = False;
            skip;
        }
        self.color[here.name] = 1;
        visit [<--][?:Scope] else {
            disengage;
        };
        self.color[here.name] = 2;
    }

    can finish with Root exit {
        report self.safe;
    }
}

def _wire(owns: dict[str, str]) -> None {
    nodes: dict[str, Scope] = {};
    for (child, parent) in owns.items() {
        if child not in nodes {
            nodes[child] = Scope(name=child);
            root ++> nodes[child];
        }
        if parent not in nodes {
            nodes[parent] = Scope(name=parent);
            root ++> nodes[parent];
        }
        nodes[child] +>:Owns:+> nodes[parent];
    }
}

def enter_scope(stack: list[str], scope_id: str, parent: str | None) -> list[str] {
    out = list(stack);
    out.append(scope_id);
    return out;
}

def exit_scope(stack: list[str]) -> list[str] {
    if not stack {
        return [];
    }
    return stack[:-1];
}

def scope_cycle_safe(owns: dict[str, str]) -> bool {
    if not owns {
        return True;
    }
    _wire(owns);
    first = list(owns.keys())[0];
    w = root spawn OwnsWalker(start=first);
    return w.reports[0] if w.reports else True;
}

def restore_on_exit(stack: list[str], target_depth: int) -> list[str] {
    if target_depth < 0 {
        return [];
    }
    if len(stack) >= target_depth {
        return stack[:target_depth];
    }
    return list(stack);
}

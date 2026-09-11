"""hertz-contrib/swagger-generate#15 — IDL schema expansion with circular reference guards.

Recursive protobuf/thrift messages crash schema generation without cycle
detection. The generator keeps a refs adjacency dict and walks it with an
explicit visiting set, emitting message names safe for $ref indirection.
"""
import from __future__ { annotations }
class SchemaGraph {
    def init(self: SchemaGraph) -> None {
        self.messages: dict[(str, bool)] = {};
        self.refs: dict[(str, list[str])] = {};
    }
    def add_message(self: SchemaGraph, name: str) -> None {
        self.messages[name] = True;
        self.refs.setdefault(name, []);
    }
    def add_ref(self: SchemaGraph, src: str, dst: str) -> None {
        if ((src in self.messages) and (dst in self.messages)) {
            self.refs[src].append(dst);
        }
    }
}
def load_messages(messages: list[str], refs: list[tuple[(str, str)]]) -> SchemaGraph {
    g = SchemaGraph();
    for m in messages {
        g.add_message(m);
    }
    for (src, dst) in refs {
        g.add_ref(src, dst);
    }
    return g;
}
def safe_schema_names(g: SchemaGraph, roots: list[str]) -> list[str] {
    emitted: set[str] = `set();
    visiting: set[str] = `set();
    def _walk(name: str) -> None {
        if (name in visiting) {
            return;
        }
        if (name in emitted) {
            return;
        }
        if (name not in g.messages) {
            return;
        }
        visiting.add(name);
        emitted.add(name);
        for nxt in g.refs.get(name, []) {
            _walk(nxt);
        }
        visiting.discard(name);
    }
    for r in roots {
        _walk(r);
    }
    return sorted(emitted);
}
def has_cycle(g: SchemaGraph, start: str) -> bool {
    visiting: set[str] = `set();
    stack: list[str] = [start];
    def _dfs(name: str) -> bool {
        if (name in visiting) {
            return True;
        }
        if (name not in g.messages) {
            return False;
        }
        visiting.add(name);
        for nxt in g.refs.get(name, []) {
            if _dfs(nxt) {
                return True;
            }
        }
        visiting.discard(name);
        return False;
    }
    if (start not in g.messages) {
        return False;
    }
    return _dfs(start);
}


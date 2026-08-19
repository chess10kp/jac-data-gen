node OpCell { has name: str; has op: str; has val: int; }

walker EvalCell {
    has result: int = 0;
    can fold with OpCell entry {
        children = [-->];
        if not children { self.result = here.val; }
        else {
            parts = [];
            for c in children { parts.append((c spawn EvalCell()).result); }
            if here.op == "+" { self.result = sum(parts); }
            else {
                r = 1;
                for p in parts { r *= p; }
                self.result = r;
            }
        }
    }
}

def eval_op_tree(spec: dict) -> int {
    kids: dict = dict(spec["kids"]); ops: dict = dict(spec["ops"]); vals: dict = dict(spec["vals"]);
    nodes: dict = {};
    for (p, cs) in kids.items() {
        if p not in nodes { nodes[p] = OpCell(name=str(p), op=str(ops.get(p, "")), val=int(vals.get(p, 0))); }
        for c in cs {
            if c not in nodes { nodes[c] = OpCell(name=str(c), op=str(ops.get(c, "")), val=int(vals.get(c, 0))); }
        }
    }
    base: str = str(spec["base"]);
    if base not in nodes { nodes[base] = OpCell(name=base, op=str(ops.get(base, "")), val=int(vals.get(base, 0))); }
    for (p, cs) in kids.items() { for c in cs { nodes[p] ++> nodes[c]; } }
    return (nodes[base] spawn EvalCell()).result;
}

with entry {
    print(eval_op_tree({'kids': {'e': ['f', 'g'], 'f': ['x', 'y']}, 'ops': {'e': '+', 'f': '*'}, 'vals': {'x': 2, 'y': 3, 'g': 4}, 'base': 'e'}));
}

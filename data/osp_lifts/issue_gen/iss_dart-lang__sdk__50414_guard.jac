# dart-lang/sdk#50414 — horizontal inference over record literals:
# flatten an argument tree (record literals, conditional spreads) into a
# left-to-right list of function arguments for inference.

node ArgExpr {
    has kind: str;          # "plain" | "record" | "if_spread"
    has text: str;
    has infer_type: str = "dynamic";
    has children: list[ArgExpr] = static ();
}

edge Holds {}              # syntactic containment (record/if -> child arg)

def flatten_args(arg_node: ArgExpr) -> list[ArgExpr] {
    # DFS through record-literal / if-spread children; leaves in order.
    out: list[ArgExpr] = [];
    stack: list[ArgExpr] = [arg_node];
    while len(stack) {
        cur: ArgExpr = stack.pop();
        if len(cur.children) == 0 {
            out.append(cur);
        } else {
            for ch in cur.children {
                stack.append(ch);
            }
        }
    }
    return out;
}

walker HorizontalInfer {
    has claimed: dict[bool] = {};
    has inferred: list[str] = [];

    can step with ArgExpr entry {
        if self.claimed.get(here.text, False) { skip; }
        self.claimed[here.text] = True;
        # horizontal inference: propagate inward over flattened leaves
        leaves = flatten_args(here);
        for leaf in leaves {
            if leaf.infer_type == "dynamic" and len(self.inferred) {
                leaf.infer_type = self.inferred[-1];
            }
            self.inferred.append(leaf.infer_type);
        }
        kids: list[ArgExpr] = [here ->:Holds:->];
        if len(kids) == 0 {
            disengage;
        }
        visit kids;
    }
}

def infer_record_literal(lit: ArgExpr) -> list[str] {
    # Public entry: walk the literal, return inferred leaf types in order.
    w = lit spawn HorizontalInfer(claimed={});
    return w.inferred;
}

def infer_call(arg_list: list[ArgExpr]) -> list[str] {
    # Flatten all top-level args (descending into records/spreads).
    types: list[str] = [];
    for a in arg_list {
        for leaf in flatten_args(a) {
            types.append(leaf.infer_type);
        }
    }
    return types;
}

with entry {
    # foldRec((0, (a, b) => a + b)) — nested record literal
    inner = ArgExpr(kind="plain", text="closure", infer_type="Function(T,E)");
    seed = ArgExpr(kind="plain", text="0", infer_type="int");
    rec = ArgExpr(kind="record", text="rec", infer_type="dynamic");
    root_node = ArgExpr(kind="record", text="top", infer_type="dynamic");
    root_node ++> seed;
    root_node ++> inner;
    rec ++> seed;
    rec ++> inner;
    rec ++> root_node;
    print(infer_record_literal(rec));
    print(infer_call([rec, inner]));
}

test "diamond_revisit_flattens_each_leaf_once" {
    a = ArgExpr(kind="plain", text="0", infer_type="int");
    b = ArgExpr(kind="record", text="d", infer_type="dynamic");
    c = ArgExpr(kind="plain", text="f", infer_type="dynamic");
    top = ArgExpr(kind="record", text="t", infer_type="dynamic");
    top ++> a; top ++> b; top ++> c;
    b ++> a; b ++> c;
    assert infer_record_literal(top) == ["int", "int", "dynamic"];
}

test "unknown_arg_kind_tolerated" {
    odd = ArgExpr(kind="spread_mystery", text="?", infer_type="dynamic");
    assert infer_record_literal(odd) == ["dynamic"];
}

test "empty_record_yields_empty" {
    empty = ArgExpr(kind="record", text="()", infer_type="dynamic");
    assert infer_record_literal(empty) == [];
}

test "deep_nesting_flatten_order" {
    leaf1 = ArgExpr(kind="plain", text="x", infer_type="int");
    leaf2 = ArgExpr(kind="plain", text="y", infer_type="num");
    mid = ArgExpr(kind="record", text="m", infer_type="dynamic");
    outer = ArgExpr(kind="record", text="o", infer_type="dynamic");
    outer ++> leaf1; outer ++> mid;
    mid ++> leaf2;
    assert infer_call([outer]) == ["int", "num"];
}

test "deep_diamond_adversarial_order" {
    shared = ArgExpr(kind="plain", text="s", infer_type="int");
    late_branch = ArgExpr(kind="record", text="L", infer_type="dynamic");
    early_branch = ArgExpr(kind="record", text="E", infer_type="dynamic");
    early_branch ++> shared;
    root_rec = ArgExpr(kind="record", text="R", infer_type="dynamic");
    root_rec ++> early_branch; root_rec ++> late_branch;
    late_branch ++> shared;
    assert infer_record_literal(root_rec) == ["int", "int"];
}

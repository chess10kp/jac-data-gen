# iss_BigWhale__sushi-lang__677.jac
# Synthetic lift: inline recursive type cycles (struct + enum payloads) -> one CE2095 each.

node TypeNode {
    has name: str;
    has kind: str;
    has line: int = 1;
    has cid: str = "";
}

edge Ref {}

walker CycleCollectWalker {
    has claimed: dict[str, bool] = {};
    has stack: list[str] = [];
    has on_path: dict[str, bool] = {};
    has names: dict[str, str] = {};
    has lines: dict[str, int] = {};
    has found: list[tuple[str, int, str]] = [];
    has seen_cycle: dict[str, bool] = {};

    can step with TypeNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.on_path[here.cid] = True;
        self.stack.append(here.cid);

        kids: list[TypeNode] = [];
        for ch in [here ->:Ref:->][?:TypeNode] {
            kid_id = ch.cid;
            if kid_id in self.on_path {
                cyc_names: list[str] = [];
                start_idx = 0;
                for i in range(len(self.stack)) {
                    if self.stack[i] == kid_id {
                        start_idx = i;
                    }
                }
                for j in range(start_idx, len(self.stack)) {
                    cyc_names.append(self.names[self.stack[j]]);
                }
                cyc_names.append(self.names[kid_id]);
                key_parts: list[str] = [];
                for nm in cyc_names {
                    key_parts.append(nm);
                }
                key_parts = sorted(key_parts);
                key = "";
                for kp in key_parts {
                    key = key + kp + "|";
                }
                if key not in self.seen_cycle {
                    chain = join_refers(cyc_names);
                    rep_line = self.lines[self.stack[start_idx]];
                    for cid in self.stack {
                        if self.lines[cid] < rep_line {
                            rep_line = self.lines[cid];
                        }
                    }
                    if self.lines[kid_id] < rep_line {
                        rep_line = self.lines[kid_id];
                    }
                    self.found.append(("CE2095", rep_line, chain));
                    self.seen_cycle[key] = True;
                }
            } else {
                kids.append(ch);
            }
        }

        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }

        stk = self.stack;
        if len(stk) > 0 and stk[len(stk) - 1] == here.cid {
            _ = stk.pop();
        }
        self.on_path[here.cid] = False;
        print("cycle_probe", here.name, len(self.found));
    }
}

def join_refers(parts: list[str]) -> str {
    if len(parts) == 0 {
        return "";
    }
    out = parts[0];
    for i in range(1, len(parts)) {
        out = out + " refers to " + parts[i];
    }
    return out;
}

def build_graph(specs: list[tuple[str, str, int, list[str]]]) -> TypeNode {
    index: dict[str, TypeNode] = {};
    order: list[str] = [];
    for spec in specs {
        nm = spec[0];
        kd = spec[1];
        ln = spec[2];
        nd = TypeNode(name=nm, kind=kd, line=ln, cid=nm);
        index[nm] = nd;
        order.append(nm);
    }
    graph_root: TypeNode = index[order[0]];
    for spec in specs {
        nm = spec[0];
        refs = spec[3];
        src = index[nm] as TypeNode;
        root ++> src;
        for rname in refs {
            if rname in index {
                dst = index[rname] as TypeNode;
                src +>:Ref:+> dst;
            }
        }
    }
    return graph_root;
}

def inline_cycle_reports(specs: list[tuple[str, str, int, list[str]]]) -> list[tuple[str, int, str]] {
    graph_root = build_graph(specs);
    names: dict[str, str] = {};
    lines: dict[str, int] = {};
    for spec in specs {
        names[spec[0]] = spec[0];
        lines[spec[0]] = spec[2];
    }
    w: CycleCollectWalker;
    with entry {
        w = graph_root spawn CycleCollectWalker(
            claimed={},
            stack=[],
            on_path={},
            names=names,
            lines=lines,
            found=[],
            seen_cycle={}
        );
    }
    out: list[tuple[str, int, str]] = [];
    for row in sorted(w.found) {
        out.append(row);
    }
    return out;
}

def collapse_reports(rows: list[tuple[str, int, str]]) -> list[tuple[str, int, str]] {
    seen: dict[str, bool] = {};
    out: list[tuple[str, int, str]] = [];
    for row in rows {
        key = row[0] + "|" + str(row[1]) + "|" + row[2];
        if key not in seen {
            seen[key] = True;
            out.append(row);
        }
    }
    return out;
}

def multi_pass_inline_reports(
    specs: list[tuple[str, str, int, list[str]]],
    passes: int
) -> list[tuple[str, int, str]] {
    acc: list[tuple[str, int, str]] = [];
    for _p in range(passes) {
        batch = inline_cycle_reports(specs);
        for item in batch {
            acc.append(item);
        }
    }
    collapsed: list[tuple[str, int, str]] = [];
    for row in collapse_reports(acc) {
        collapsed.append(row);
    }
    final: list[tuple[str, int, str]] = [];
    for row in sorted(collapsed) {
        final.append(row);
    }
    return final;
}

"""Nested format string graph — r1chardj0n3s/parse#206."""

node FormatField {
    has cid: str;
    has name: str = "";
    has depth: int = 0;
    has spec: str = "";
    has is_named: bool = True;
}

edge Nests {}
edge Next {}

walker CollectNamesWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with FormatField entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.name != "" {
            self.order.append(here.name);
        }
        print("collect", here.cid, here.name);
        nest_kids: list[FormatField] = [here ->:Nests:->][?:FormatField];
        next_kids: list[FormatField] = [here ->:Next:->][?:FormatField];
        if nest_kids {
            visit :0: nest_kids;
        } elif next_kids {
            visit :0: next_kids;
        } else {
            disengage;
        }
    }
}

def find_matching_brace(fmt: str, start: int) -> int {
    depth = 1;
    i = start + 1;
    while i < len(fmt) {
        if fmt[i] == "\\" and i + 1 < len(fmt) {
            i = i + 2;
            continue;
        }
        if fmt[i] == "{" {
            depth = depth + 1;
        } elif fmt[i] == "}" {
            depth = depth - 1;
            if depth == 0 {
                return i;
            }
        }
        i = i + 1;
    }
    return -1;
}

def split_field_inner(inner: str) -> list[str] {
    parts: list[str] = [];
    if ":" in inner {
        idx = inner.find(":");
        parts.append(inner[0:idx]);
        parts.append(inner[idx + 1:]);
    } else {
        parts.append(inner);
        parts.append("");
    }
    return parts;
}

def materialize_fields(
    fmt: str,
    depth: int,
    max_nesting_depth: int,
    counter: list[int],
    prev: FormatField | None
) -> FormatField | None {
    if depth > max_nesting_depth {
        return None;
    }
    head: FormatField | None = None;
    cur: FormatField | None = None;
    i = 0;
    while i < len(fmt) {
        if fmt[i] == "\\" and i + 1 < len(fmt) {
            i = i + 2;
            continue;
        }
        if fmt[i] != "{" {
            i = i + 1;
            continue;
        }
        end = find_matching_brace(fmt, i);
        if end < 0 {
            return None;
        }
        inner = fmt[i + 1:end];
        chunks = split_field_inner(inner);
        fname = chunks[0].strip();
        fspec = chunks[1].strip();
        counter[0] = counter[0] + 1;
        cid = "f" + str(counter[0]);
        is_named = True;
        if fname == "" {
            is_named = False;
            fname = str(counter[0] - 1);
        }
        nd = FormatField(cid=cid, name=fname, depth=depth, spec=fspec, is_named=is_named);
        root ++> nd;
        if fspec != "" and fspec[0] == "{" {
            child = materialize_fields(fspec, depth + 1, max_nesting_depth, counter, nd);
            if child is None {
                return None;
            }
            nd +>:Nests:+> child;
        }
        if head is None {
            head = nd;
            cur = nd;
        } else {
            if cur is not None {
                cur +>:Next:+> nd;
            }
            cur = nd;
        }
        i = end + 1;
    }
    return head;
}

def build_format_graph(fmt: str, max_nesting_depth: int = 10) -> dict | None {
    counter: list[int] = [0];
    head = materialize_fields(fmt, 0, max_nesting_depth, counter, None);
    if head is None {
        stripped = fmt.replace("\\{", "");
        if "{" in stripped {
            return None;
        }
        return None;
    }
    nodes: dict[str, FormatField] = {};
    stack: list[FormatField] = [head];
    while len(stack) > 0 {
        nd = stack.pop();
        nodes[nd.cid] = nd;
        nk: list[FormatField] = [nd ->:Nests:->][?:FormatField];
        xk: list[FormatField] = [nd ->:Next:->][?:FormatField];
        for k in nk {
            stack.append(k);
        }
        for k in xk {
            stack.append(k);
        }
    }
    out: dict = {};
    out["root"] = head.cid;
    out["nodes"] = nodes;
    return out;
}

def collect_nested_names(graph_root: str, store: dict) -> list[str] {
    nodes = store["nodes"] as dict[str, FormatField];
    if graph_root not in nodes {
        return [];
    }
    root_nd = nodes[graph_root];
    w = root_nd spawn CollectNamesWalker(claimed={}, order=[]);
    return w.order;
}

def remove_named_fields(graph_root: str, drop_names: list[str], store: dict) -> dict {
    nodes = store["nodes"] as dict[str, FormatField];
    drop_set: dict[str, bool] = {};
    for nm in drop_names {
        drop_set[nm] = True;
    }
    kept: dict[str, FormatField] = {};
    for cid in nodes {
        nd = nodes[cid];
        if nd.name in drop_set {
            continue;
        }
        kept[cid] = nd;
    }
    out: dict = {};
    out["root"] = graph_root;
    out["nodes"] = kept;
    return out;
}

def parse_field_value(text: str, nd: FormatField, nodes: dict[str, FormatField]) -> dict | None {
    result: dict[str, str] = {};
    if nd.spec == "d" {
        j = 0;
        while j < len(text) {
            ch = text[j];
            if ch >= "0" and ch <= "9" {
                j = j + 1;
            } else {
                break;
            }
        }
        if j == 0 {
            return None;
        }
        result[nd.name] = text[0:j];
        rest = text[j:];
        nk: list[FormatField] = [nd ->:Nests:->][?:FormatField];
        if nk {
            sub = parse_field_value(rest, nk[0], nodes);
            if sub is None {
                return None;
            }
            for k in sub {
                result[k] = sub[k];
            }
        }
        return result;
    }
    result[nd.name] = text;
    nk2: list[FormatField] = [nd ->:Nests:->][?:FormatField];
    if nk2 {
        sub2 = parse_field_value("", nk2[0], nodes);
        if sub2 is None {
            return None;
        }
        for k in sub2 {
            result[k] = sub2[k];
        }
    }
    return result;
}

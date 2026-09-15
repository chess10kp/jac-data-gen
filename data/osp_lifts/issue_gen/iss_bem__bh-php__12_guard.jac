"""WeakJSONParser recursive comment parsing — bem/bh-php#12."""

node Seg {
    has sid: str;
    has kind: str;
    has start: int;
    has end: int;
    has raw: str;
}

edge Nest {}

walker SpanWalk {
    has claimed: dict[str, bool] = {};
    has spans: list[tuple[int, int]] = [];

    can step with Seg entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        if here.kind == "line" or here.kind == "block" {
            self.spans.append((here.start, here.end));
        }
        kids: list[Seg] = [];
        for ch in [here ->:Nest:->][?:Seg] {
            kids.append(ch);
        }
        visit :0: kids else {
            disengage;
        }
        print("visit", here.sid, here.kind);
    }
}

def scan_line_comment(pos: int, src: str, sid: str) -> tuple[int, Seg] {
    start = pos;
    n = len(src);
    i = pos + 2;
    while i < n and src[i] != "\n" {
        i += 1;
    }
    end = i;
    if i < n {
        end = i + 1;
    }
    raw = src[start:end];
    nd = Seg(sid=sid, kind="line", start=start, end=end, raw=raw);
    return (end, nd);
}

def scan_block_comment(pos: int, src: str, sid: str, seq: int) -> tuple[int, Seg, int] {
    start = pos;
    n = len(src);
    i = pos + 2;
    nd = Seg(sid=sid, kind="block", start=start, end=-1, raw="");
    next_seq = seq;
    while i < n {
        if i + 1 < n and src[i] == "/" and src[i + 1] == "*" {
            cid = "c" + str(next_seq);
            next_seq += 1;
            br = scan_block_comment(i, src, cid, next_seq);
            i = br[0];
            child = br[1];
            next_seq = br[2];
            nd +>:Nest:+> child;
        } elif i + 1 < n and src[i] == "*" and src[i + 1] == "/" {
            i += 2;
            nd.end = i;
            nd.raw = src[start:i];
            return (i, nd, next_seq);
        } else {
            i += 1;
        }
    }
    nd.end = n;
    nd.raw = src[start:n];
    return (n, nd, next_seq);
}

def build_graph(src: str) -> Seg {
    graph_root = Seg(sid="root", kind="root", start=0, end=len(src), raw=src);
    n = len(src);
    i = 0;
    seq = 0;
    while i < n {
        if i + 1 < n and src[i] == "/" and src[i + 1] == "/" {
            cid = "c" + str(seq);
            seq += 1;
            lr = scan_line_comment(i, src, cid);
            i = lr[0];
            graph_root +>:Nest:+> lr[1];
        } elif i + 1 < n and src[i] == "/" and src[i + 1] == "*" {
            cid = "c" + str(seq);
            seq += 1;
            br = scan_block_comment(i, src, cid, seq);
            i = br[0];
            graph_root +>:Nest:+> br[1];
            seq = br[2];
        } else {
            i += 1;
        }
    }
    return graph_root;
}

def contains_js(src: str) -> bool {
    markers: list[str] = ["function ", "=>", "var ", "let ", "const "];
    for m in markers {
        if m in src {
            return True;
        }
    }
    return False;
}

def extract_comment_spans(src: str) -> list[tuple[int, int]] {
    graph_root = build_graph(src);
    w = graph_root spawn SpanWalk(claimed={}, spans=[]);
    out: list[tuple[int, int]] = sorted(w.spans);
    return out;
}

def strip_comments(src: str) -> str {
    spans = extract_comment_spans(src);
    if len(spans) == 0 {
        return src;
    }
    parts: list[str] = [];
    cursor = 0;
    for sp in spans {
        st = sp[0];
        en = sp[1];
        if st > cursor {
            parts.append(src[cursor:st]);
        }
        cursor = en;
    }
    if cursor < len(src) {
        parts.append(src[cursor:]);
    }
    result = "";
    for p in parts {
        result += p;
    }
    return result;
}

def has_unclosed_comment(src: str) -> bool {
    n = len(src);
    depth = 0;
    i = 0;
    while i < n {
        if i + 1 < n and src[i] == "/" and src[i + 1] == "*" {
            depth += 1;
            i += 2;
        } elif i + 1 < n and src[i] == "*" and src[i + 1] == "/" {
            if depth > 0 {
                depth -= 1;
            }
            i += 2;
        } else {
            i += 1;
        }
    }
    return depth > 0;
}

def parse_weak(src: str, skip_comments: bool = False, fail_on_js: bool = False) -> str {
    if fail_on_js and contains_js(src) {
        raise Exception("js_code");
    }
    if skip_comments {
        return src;
    }
    return strip_comments(src);
}

test "line_comment_span" {
    spans = extract_comment_spans("x//a\ny");
    assert len(spans) == 1;
    assert spans[0][0] == 1;
    assert spans[0][1] == 5;
}

test "nested_block_spans_sorted" {
    spans = extract_comment_spans("/* o /* i */ m */");
    assert len(spans) == 2;
    assert spans[0][0] < spans[1][0];
}

test "strip_comments_removes" {
    out = strip_comments("keep//drop\nend");
    assert out == "keepend";
}

test "has_unclosed_true" {
    assert has_unclosed_comment("/* open") == True;
}

test "has_unclosed_false" {
    assert has_unclosed_comment("/* closed */") == False;
}

test "parse_weak_skip_comments" {
    src = "a/*b*/c";
    assert parse_weak(src, skip_comments=True) == src;
}

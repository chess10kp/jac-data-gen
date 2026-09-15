"""mscdex/node-imap#818 — hierarchical partID assignment for nested message/rfc822 bodies."""

node MimePart {
    has part_id: str = "";
    has type: str = "";
    has subtype: str = "";
    has name: str = "";
}

edge Child {}

node GraphCtx {
    has graph_root: MimePart;
}

walker RenumberWalker {
    has claimed: dict[str, bool] = {};
    has prefix: str = "";
    has ordered: list[str] = [];

    can renumber with MimePart entry {
        kids: list[MimePart] = [here ->:Child:->][?:MimePart];
        if len(kids) == 0 {
            disengage;
        }
        idx: int = 0;
        for ch in kids {
            idx += 1;
            new_id: str = "";
            if self.prefix == "" {
                new_id = str(idx);
            } else {
                new_id = self.prefix + "." + str(idx);
            }
            ch.part_id = new_id;
            self.ordered.append(new_id);
            print(new_id);
            w = ch spawn RenumberWalker(
                prefix=new_id, claimed=self.claimed, ordered=self.ordered
            );
        }
    }
}

walker CollectWalker {
    has claimed: dict[str, bool] = {};
    has labels: list[str] = [];

    can step with MimePart entry {
        lid: str = part_label(here);
        if lid in self.claimed {
            skip;
        }
        self.claimed[lid] = True;
        self.labels.append(lid);
        print(lid);
        kids: list[MimePart] = [here ->:Child:->][?:MimePart];
        for kid in kids {
            visit :0: [kid];
        }
    }
}

walker LookupWalker {
    has target: str = "";
    has found: dict | None = None;
    has claimed: dict[str, bool] = {};

    can seek with MimePart entry {
        if here.part_id in self.claimed {
            skip;
        }
        self.claimed[here.part_id] = True;
        if here.part_id == self.target {
            self.found = {
                "type": here.type,
                "subtype": here.subtype,
                "part_id": here.part_id,
                "name": here.name,
            };
            print(here.part_id);
            disengage;
        }
        kids: list[MimePart] = [here ->:Child:->][?:MimePart];
        for kid in kids {
            visit :0: [kid];
        }
    }
}

def part_label(p: MimePart) -> str {
    if p.name != "" {
        return p.name;
    }
    if p.part_id != "" {
        return p.part_id;
    }
    return "root";
}

def build_eml_pdf_fixture() -> GraphCtx {
    mixed = MimePart(type="multipart", subtype="mixed", part_id="");
    html = MimePart(type="text", subtype="html", part_id="1");
    rfc = MimePart(
        type="message", subtype="rfc822", part_id="2", name="attachment.eml"
    );
    pdf = MimePart(
        type="application", subtype="pdf", part_id="2", name="20200910.pdf"
    );
    mixed +>:Child:+> html;
    mixed +>:Child:+> rfc;
    rfc +>:Child:+> pdf;
    return GraphCtx(graph_root=mixed);
}

def build_diamond_fixture() -> GraphCtx {
    mixed = MimePart(type="multipart", subtype="mixed", part_id="", name="root");
    a = MimePart(type="text", subtype="plain", part_id="", name="A");
    b = MimePart(type="text", subtype="plain", part_id="", name="B");
    d = MimePart(type="application", subtype="pdf", part_id="", name="D");
    mixed +>:Child:+> a;
    mixed +>:Child:+> b;
    a +>:Child:+> d;
    b +>:Child:+> d;
    return GraphCtx(graph_root=mixed);
}

def normalize_nested_ids(ctx: GraphCtx) -> list[str] {
    w = ctx.graph_root spawn RenumberWalker(prefix="", claimed={}, ordered=[]);
    return w.ordered;
}

def collect_visit_order(ctx: GraphCtx) -> list[str] {
    w = ctx.graph_root spawn CollectWalker(claimed={}, labels=[]);
    return w.labels;
}

def lookup_part(ctx: GraphCtx, part_id: str) -> dict | None {
    w = ctx.graph_root spawn LookupWalker(target=part_id, claimed={}, found=None);
    return w.found;
}

test "eml_nested_hierarchical_ids" {
    ctx = build_eml_pdf_fixture();
    ids = normalize_nested_ids(ctx);
    assert ids == ["1", "2", "2.1"];
    pdf = lookup_part(ctx, "2.1");
    assert pdf is not None;
    assert pdf["type"] == "application";
    assert pdf["subtype"] == "pdf";
    assert pdf["name"] == "20200910.pdf";
}

test "diamond_revisit_visits_once" {
    ctx = build_diamond_fixture();
    labels = collect_visit_order(ctx);
    d_count: int = 0;
    for lb in labels {
        if lb == "D" {
            d_count += 1;
        }
    }
    assert d_count == 1;
    assert "A" in labels;
    assert "B" in labels;
}

test "unknown_part_lookup_none" {
    ctx = build_eml_pdf_fixture();
    normalize_nested_ids(ctx);
    missing = lookup_part(ctx, "99");
    assert missing is None;
}

test "duplicate_prefixed_id_not_reused" {
    ctx = build_eml_pdf_fixture();
    normalize_nested_ids(ctx);
    outer = lookup_part(ctx, "2");
    inner = lookup_part(ctx, "2.1");
    assert outer is not None;
    assert inner is not None;
    assert outer["part_id"] == "2";
    assert inner["part_id"] == "2.1";
    assert outer["part_id"] != inner["part_id"];
}

test "single_child_renumbers_to_one" {
    mixed = MimePart(type="multipart", subtype="mixed", part_id="");
    lone = MimePart(type="text", subtype="plain", part_id="2");
    mixed +>:Child:+> lone;
    ctx = GraphCtx(graph_root=mixed);
    ids = normalize_nested_ids(ctx);
    assert ids == ["1"];
    got = lookup_part(ctx, "1");
    assert got is not None;
    assert got["subtype"] == "plain";
}

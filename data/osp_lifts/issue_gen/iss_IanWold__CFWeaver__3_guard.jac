"""Recursive-descent Markdown AST lift for IanWold/CFWeaver#3."""

node Ast {
    has kind: str;
    has value: str;
    has level: int = 0;
}

edge Child {}
edge Parent {}

walker OutlineWalker {
    has claimed: dict[str, bool] = {};
    has headings: list[str] = [];

    can collect with Ast entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print(here.kind);
        if here.kind == "heading" {
            self.headings.append(here.value);
        }
        for kid in [here ->:Child:->][?:Ast] {
            visit :0: [kid];
        }
    }
}

walker SearchWalker {
    has wanted: str;
    has claimed: dict[str, bool] = {};
    has found: str = "";

    can search with Ast entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print(here.kind);
        if here.cid == self.wanted {
            self.found = here.value;
        }
        for kid in [here ->:Child:->][?:Ast] {
            visit :0: [kid];
        }
    }
}

walker RenderWalker {
    has claimed: dict[str, bool] = {};
    has values: list[str] = [];

    can render with Ast entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print(here.kind);
        if here.kind != "document" {
            self.values.append(here.value);
        }
        for kid in [here ->:Child:->][?:Ast] {
            visit :0: [kid];
        }
    }
}

def parse_document(markdown: str) -> Ast {
    document = Ast(kind="document", value="");
    lines: list[str] = markdown.split("\n");
    current: Ast = document;

    for line in lines {
        clean = line.strip();
        level = 0;
        title = "";

        if clean == "#" {
            level = 1;
        } elif clean.startswith("# ") {
            level = 1;
            title = clean[2:].strip();
        } elif clean == "##" {
            level = 2;
        } elif clean.startswith("## ") {
            level = 2;
            title = clean[3:].strip();
        } elif clean == "###" {
            level = 3;
        } elif clean.startswith("### ") {
            level = 3;
            title = clean[4:].strip();

        if level > 0 {
            while current != document and current.level >= level {
                for parent in [current ->:Parent:->][?:Ast] {
                    current = parent;
                }
            }
            section = Ast(kind="heading", value=title, level=level);
            current +>:Child:+> section;
            section +>:Parent:+> current;
            current = section;
        } elif clean != "" {
            block = Ast(kind="paragraph", value=clean);
            current +>:Child:+> block;
        }
    }
    return document;
}

def collect_headings(document: Ast) -> list[str] {
    w = document spawn OutlineWalker(claimed={});
    return sorted(w.headings);
}

def lookup_text(document: Ast, node_id: str) -> str {
    w = document spawn SearchWalker(wanted=node_id, claimed={});
    return w.found;
}

def render_document(document: Ast) -> list[str] {
    w = document spawn RenderWalker(claimed={});
    return sorted(w.values);
}

test "recursive outline and rendering" {
    document = parse_document("# Intro\nbody\n## Detail\nmore");
    assert (collect_headings(document) == ["Detail", "Intro"]);
    assert (render_document(document) == ["Detail", "Intro", "body", "more"]);
}

test "diamond revisit is claimed once" {
    graph_root = Ast(kind="document", value="");
    left = Ast(kind="section", value="left");
    right = Ast(kind="section", value="right");
    shared = Ast(kind="heading", value="shared");
    leaf = Ast(kind="paragraph", value="leaf");

    graph_root +>:Child:+> left;
    graph_root +>:Child:+> right;
    left +>:Child:+> shared;
    right +>:Child:+> shared;
    shared +>:Child:+> leaf;

    assert (collect_headings(graph_root) == ["shared"]);
    assert (render_document(graph_root) == ["leaf", "left", "right", "shared"]);
}

test "unknown node id is tolerated" {
    document = parse_document("# Known");
    assert (lookup_text(document, "missing-node") == "");
}

test "known node lookup and blank input" {
    document = parse_document("\n\n");
    assert (collect_headings(document) == []);
    assert (render_document(document) == []);

    needle = Ast(kind="paragraph", value="found");
    document +>:Child:+> needle;
    assert (lookup_text(document, needle.cid) == "found");
}

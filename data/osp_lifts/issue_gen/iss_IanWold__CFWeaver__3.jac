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

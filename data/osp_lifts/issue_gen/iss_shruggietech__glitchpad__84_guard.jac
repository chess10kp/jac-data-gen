# PROGRAM: iss_shruggietech__glitchpad__84.jac
# shruggietech/glitchpad#84

node ArchiveEntry {
    has path: str;
    has compressed: int;
    has expanded: int;
    has kind: str;
    has body: str = "";
}
node Part {
    has name: str;
    has construct: str = "xml";
    has body: str = "";
}
node DocxPackage {
    has package_id: str;
}
node Relationship {
    has source: str;
    has target: str;
    has external: bool = False;
}
edge Contains {}
edge Resolves {}

walker ResolveWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can inspect_package with DocxPackage entry {
        if here.package_id in self.claimed { skip; }
        self.claimed[here.package_id] = True;
        print(here.package_id);
        for kid in [here ->:Contains:->][?:Part] {
            visit :0: [kid];
        }
    }

    can inspect_part with Part entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        print(here.name);
        for kid in [here ->:Resolves:->][?:Part] {
            visit :0: [kid];
        }
    }
}

def _xml_ok(text: str) -> bool {
    if text.find("<") < 0 { return False; }
    if text.find(">") < 0 { return False; }
    return True;
}

def _joined(values: list[str]) -> str {
    answer: str = "";
    for value in sorted(values) {
        if answer != "" { answer += ","; }
        answer += value;
    }
    return answer;
}

def validate_package(
    entries: list[ArchiveEntry],
    compressed_limit: int = 134217728,
    expanded_limit: int = 536870912,
    entry_limit: int = 4096
) -> list[str] {
    errors: list[str] = [];
    seen: dict[str, bool] = {};
    compressed_total: int = 0;
    expanded_total: int = 0;

    if len(entries) > entry_limit { errors.append("entry_limit"); }
    for entry in entries {
        if entry.path == "" { errors.append("empty_path"); }
        if entry.path.find("..") >= 0 { errors.append("traversal"); }
        if entry.path in seen {
            errors.append("duplicate:" + entry.path);
        } else {
            seen[entry.path] = True;
        }
        if entry.compressed < 0 { errors.append("negative_compressed"); }
        if entry.expanded < 0 { errors.append("negative_expanded"); }
        compressed_total += entry.compressed;
        expanded_total += entry.expanded;
        if entry.kind in ["macro", "exe", "encrypted"] {
            errors.append("forbidden:" + entry.path);
        }
        if entry.kind == "xml" {
            if _xml_ok(entry.body) == False {
                errors.append("malformed_xml:" + entry.path);
            }
        }
    }
    if compressed_total > compressed_limit { errors.append("compressed_limit"); }
    if expanded_total > expanded_limit { errors.append("expanded_limit"); }
    if "[Content_Types].xml" not in seen { errors.append("missing_content_types"); }
    if "word/document.xml" not in seen { errors.append("missing_document"); }
    return sorted(errors);
}

def resolve_relationships(
    parts: list[Part],
    relations: list[Relationship]
) -> list[str] {
    by_name: dict[str, Part] = {};
    names: list[str] = [];
    for part_node in parts {
        by_name[part_node.name] = part_node;
        names.append(part_node.name);
    }
    for rel in relations {
        if rel.external == False {
            if rel.target.find("..") < 0 {
                if rel.source in by_name {
                    if rel.target in by_name {
                        by_name[rel.source] +>:Resolves:+> by_name[rel.target];
                    }
                }
            }
        }
    }
    if len(names) == 0 { return []; }
    ordered: list[str] = sorted(names);
    root_node: Part = by_name[ordered[0]];
    if "word/document.xml" in by_name {
        root_node = by_name["word/document.xml"];
    }
    w = root_node spawn ResolveWalk(claimed={});
    return sorted(w.found);
}

def ingest_docx(
    entries: list[ArchiveEntry],
    relations: list[Relationship] | None = None
) -> dict[str, str] {
    rels: list[Relationship] = [];
    errors: list[str] = validate_package(entries);
    if relations != None {
        rels = relations;
        for rel in rels {
            if rel.external { errors.append("external:" + rel.target); }
            if rel.target.find("..") >= 0 { errors.append("traversal_target"); }
        }
    }
    result: dict[str, str] = {};
    if len(errors) > 0 {
        result["status"] = "rejected";
        result["errors"] = _joined(errors);
        result["parts"] = "";
        result["omitted"] = "";
        return result;
    }

    package_node = DocxPackage(package_id="docx");
    part_nodes: list[Part] = [];
    omitted: list[str] = [];
    for entry in entries {
        if entry.kind == "xml" {
            part_node = Part(name=entry.path, construct=entry.kind, body=entry.body);
            part_nodes.append(part_node);
            package_node +>:Contains:+> part_node;
        } else {
            omitted.append(entry.path);
        }
    }
    by_name: dict[str, Part] = {};
    for part_node in part_nodes { by_name[part_node.name] = part_node; }
    for rel in rels {
        if rel.external == False {
            if rel.source in by_name {
                if rel.target in by_name {
                    by_name[rel.source] +>:Resolves:+> by_name[rel.target];
                }
            }
        }
    }
    w = package_node spawn ResolveWalk(claimed={});
    result["status"] = "accepted";
    result["errors"] = "";
    result["parts"] = _joined(w.found);
    result["omitted"] = _joined(omitted);
    return result;
}

test "diamond revisit remains complete" {
    a = Part(name="a");
    b = Part(name="b");
    c = Part(name="c");
    d = Part(name="d");
    a +>:Resolves:+> b;
    a +>:Resolves:+> c;
    b +>:Resolves:+> d;
    c +>:Resolves:+> d;
    assert (resolve_relationships([a, b, c, d], []) == ["a", "b", "c", "d"]);
}

test "unknown relationship ids are tolerated" {
    doc = Part(name="word/document.xml", body="<w:document></w:document>");
    ghost = Relationship(source="missing.xml", target="unknown.xml");
    assert (resolve_relationships([doc], [ghost]) == ["word/document.xml"]);
}

test "archive limits and unsafe entries are rejected" {
    bad = ArchiveEntry(path="../evil.xml", compressed=5, expanded=20, kind="xml", body="<x>");
    duplicate = ArchiveEntry(path="../evil.xml", compressed=1, expanded=1, kind="xml", body="<x>");
    errors = validate_package([bad, duplicate], compressed_limit=4, expanded_limit=10);
    assert ("traversal" in errors);
    assert ("compressed_limit" in errors);
    assert ("expanded_limit" in errors);
    assert ("duplicate:../evil.xml" in errors);
}

test "valid package preserves omitted evidence" {
    types = ArchiveEntry(path="[Content_Types].xml", compressed=10, expanded=20, kind="xml", body="<types>");
    document = ArchiveEntry(path="word/document.xml", compressed=20, expanded=40, kind="xml", body="<document>");
    drawing = ArchiveEntry(path="word/media/image.bin", compressed=3, expanded=6, kind="drawing", body="");
    header = ArchiveEntry(path="word/header.xml", compressed=5, expanded=10, kind="xml", body="<header>");
    rel = Relationship(source="word/document.xml", target="word/header.xml");
    result = ingest_docx([types, document, drawing, header], [rel]);
    assert (result["status"] == "accepted");
    assert (result["omitted"] == "word/media/image.bin");
    assert (result["parts"] == "[Content_Types].xml,word/document.xml,word/header.xml");
}

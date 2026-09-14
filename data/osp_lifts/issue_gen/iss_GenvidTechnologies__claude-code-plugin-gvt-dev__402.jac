"""GenvidTechnologies/claude-code-plugin-gvt-dev#402."""

node RawDir {
    has cid: str;
    has path: str;
}

node Capture {
    has cid: str;
    has path: str;
    has size: int = 0;
}

node Citation {
    has resource: str;
    has resolved: str;
}

node WikiPage {
    has cid: str;
    has path: str;
}

node Bundle {
    has cid: str;
    has raw_root: RawDir;
}

edge HasRaw {}
edge HasPage {}
edge ContainsDir {}
edge ContainsFile {}
edge HasSource {}

def resolve_source(page_path: str, resource: str) -> str {
    base: list[str] = [];
    page_parts = page_path.split("/");
    i: int = 0;
    while i < len(page_parts) - 1 {
        if page_parts[i] != "" {
            base.append(page_parts[i]);
        }
        i += 1;
    }

    resolved: str = "";
    for part in resource.split("/") {
        if part == ".." {
            if len(base) > 0 {
                base.pop();
            }
        } else {
            if part != "" {
                if part != "." {
                    base.append(part);
                }
            }
        }
    }

    for part in base {
        if resolved == "" {
            resolved = part;
        } else {
            resolved = resolved + "/" + part;
        }
    }
    return resolved;
}

def make_bundle(bundle_id: str) -> Bundle {
    raw_root: RawDir = RawDir(cid="raw", path="raw");
    bundle: Bundle = Bundle(cid=bundle_id, raw_root=raw_root);
    bundle +>:HasRaw:+> raw_root;
    return bundle;
}

def add_raw_dir(parent: RawDir, name: str) -> RawDir {
    full_path: str = parent.path + "/" + name;
    child: RawDir = RawDir(cid=full_path, path=full_path);
    parent +>:ContainsDir:+> child;
    return child;
}

def add_capture(parent: RawDir, name: str, size: int) -> Capture {
    full_path: str = parent.path + "/" + name;
    capture: Capture = Capture(cid=full_path, path=full_path, size=size);
    parent +>:ContainsFile:+> capture;
    return capture;
}

def add_page(
    bundle: Bundle,
    page_path: str,
    resources: list[str] | None = None
) -> WikiPage {
    page: WikiPage = WikiPage(cid=page_path, path=page_path);
    bundle +>:HasPage:+> page;

    source_list: list[str] = [];
    if resources != None {
        for resource in resources {
            source_list.append(resource);
        }
    }

    for resource in source_list {
        citation: Citation = Citation(
            resource=resource,
            resolved=resolve_source(page_path, resource)
        );
        page +>:HasSource:+> citation;
    }
    return page;
}

walker ScanRaw {
    has claimed: dict[str, bool] = {};
    has found: list[Capture] = [];

    can scan_bundle with Bundle entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("scan bundle " + here.cid);
        for kid in [here ->:HasRaw:->][?:RawDir] {
            visit :0: [kid];
        }
    }

    can scan_dir with RawDir entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("scan directory " + here.path);
        for kid in [here ->:ContainsDir:->][?:RawDir] {
            visit :0: [kid];
        }
        for kid in [here ->:ContainsFile:->][?:Capture] {
            visit :0: [kid];
        }
    }

    can scan_file with Capture entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("scan capture " + here.path);
        self.found.append(here);
    }
}

walker CollectRefs {
    has claimed: dict[str, bool] = {};
    has referenced: dict[str, bool] = {};

    can collect_bundle with Bundle entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("collect bundle " + here.cid);
        for kid in [here ->:HasPage:->][?:WikiPage] {
            visit :0: [kid];
        }
    }

    can collect_page with WikiPage entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("collect page " + here.path);
        for citation in [here ->:HasSource:->][?:Citation] {
            self.referenced[citation.resolved] = True;
        }
    }
}

def lint(bundle: Bundle) -> dict[str, int] {
    raw_scan: ScanRaw = bundle spawn ScanRaw(claimed={});
    ref_scan: CollectRefs = bundle spawn CollectRefs(claimed={});
    report: dict[str, int] = {};

    for capture in raw_scan.found {
        if capture.path not in ref_scan.referenced {
            report[capture.path] = capture.size;
        }
    }
    return report;
}

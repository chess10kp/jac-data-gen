# graph/impl/builder.impl.jac

import from graph.nodes { FileNode, DependencyNode, DocumentationNode, TestNode }
import from integrations.github { get_repo_tree, fetch_file_content }
import from lib.manifest { parse_manifest_deps }
import from jaclang { JacRuntimeInterface as Jac }
import from os { walk as os_walk }
import from os.path { splitext, join, relpath, dirname, normpath, abspath }
import from ast { parse, walk, Import as AstImport, ImportFrom }
import from re { findall }

impl GraphBuilderWalker.build with Root entry {
    existing = [root -->][?:FileNode];
    path_to_node: dict[str, FileNode] = {};
    if len(existing) > 0 and not self.force {
        report {
            "status": "already_built",
            "nodes_built": len(existing),
            "message": "Graph exists; pass force=true to upsert"
        };
        return;
    }
    if self.force {
        stale_nodes = [];
        for fn in existing {
            stale_nodes.append(fn);
        }
        for dn in [root -->][?:DependencyNode] {
            stale_nodes.append(dn);
        }
        for docn in [root -->][?:DocumentationNode] {
            stale_nodes.append(docn);
        }
        for tn in [root -->][?:TestNode] {
            stale_nodes.append(tn);
        }
        if len(stale_nodes) > 0 {
            Jac.destroy(stale_nodes);
        }
        existing = [];
    }
    self.file_count = 0;
    self.edge_count = 0;
    for fn in existing {
        path_to_node[fn.path] = fn;
    }
    tree = [];
    source_kind = "local";
    base_dir = abspath(self.repo_root);
    if self.repo_name.strip() {
        source_kind = "github";
        tree = get_repo_tree(self.repo_name, self.branch);
    } else {
        for item in os_walk(base_dir) {
            dir_path = str(item[0]);
            file_names = item[2];
            for fname in file_names {
                abs_path = join(dir_path, str(fname));
                rel_path = relpath(abs_path, base_dir).replace("\\", "/");
                tree.append({"path": rel_path, "type": "blob"});
            }
        }
    }
    for item in tree {
        path = item["path"];
        if self._should_skip(path) {
            continue;
        }
        ext = splitext(path)[1];
        ext_l = ext.lower();
        allowed = False;
        for ae in self.allowed_extensions {
            if ext_l == str(ae).lower() {
                allowed = True;
                break;
            }
        }
        if not allowed {
            continue;
        }
        content = "";
        if source_kind == "github" {
            content = fetch_file_content(self.repo_name, path, self.branch);
        } else {
            content = self._read_local_file(join(base_dir, path));
        }
        lang = self._detect_language(path);
        is_t = "test" in path.lower() or "/tests/" in path.replace("\\", "/") or path.startswith("tests/");
        if path in path_to_node {
            fnode = path_to_node[path];
            fnode.content = str(content);
            fnode.language = lang;
            fnode.is_test = bool(is_t);
        } else {
            fnode = ((root ++> FileNode(path=path, content=str(content), language=lang, is_test=bool(is_t)))[0] as FileNode);
            path_to_node[path] = fnode;
            self.file_count += 1;
        }
    }
    manifest_markers = ["package.json", "requirements.txt", "pyproject.toml", "jac.toml"];
    for mnode in [root -->][?:FileNode] {
        mp = mnode.path;
        hit = False;
        for m in manifest_markers {
            if mp.endswith(m) {
                hit = True;
                break;
            }
        }
        if not hit {
            continue;
        }
        deps = parse_manifest_deps(mp, str(mnode.content));
        eco = "pip";
        if mp.endswith("package.json") {
            eco = "npm";
        }
        for (pkg, ver) in deps.items() {
            depn = (root ++> DependencyNode(package_name=pkg, normalized_name=str(pkg).lower(), version_spec=str(ver), ecosystem=eco))[0];
            depn ++> mnode;
            self.edge_count += 1;
        }
    }
    import_edge_keys: set[str] = set();
    for fnode in [root -->][?:FileNode] {
        imported_paths = self._import_targets(fnode.path, fnode.language, str(fnode.content));
        for imp_path in imported_paths {
            ek = fnode.path + "->" + str(imp_path);
            if ek in import_edge_keys {
                continue;
            }
            tgt = path_to_node.get(str(imp_path));
            if tgt is not None {
                fnode ++> tgt;
                import_edge_keys.add(ek);
                self.edge_count += 1;
            }
        }
    }
    for fnode in [root -->][?:FileNode] {
        fp = fnode.path;
        if fp.startswith("docs/") and fp.lower().endswith(".md") {
            d = (root ++> DocumentationNode(path=fp, title=fp))[0];
            fnode ++> d;
            self.edge_count += 1;
        }
        if fnode.is_test {
            t = (root ++> TestNode(path=fp, module_guess=fp))[0];
            fnode ++> t;
            self.edge_count += 1;
        }
    }
    report {
        "status": "complete",
        "nodes_built": self.file_count,
        "edges_built": self.edge_count,
        "source": source_kind,
        "repo": self.repo_name if self.repo_name.strip() else "local",
        "repo_root": base_dir,
        "branch": self.branch
    };
}

impl GraphBuilderWalker._should_skip(path: str) -> bool {
    for sp in self.skip_paths {
        if sp in path {
            return True;
        }
    }
    return False;
}

impl GraphBuilderWalker._detect_language(filename: str) -> str {
    ext = splitext(filename)[1];
    em: dict[str, str] = {".jac": "jac", ".py": "python", ".json": "json", ".toml": "toml", ".txt": "text", ".md": "markdown"};
    return em.get(ext.lower(), "unknown");
}

impl GraphBuilderWalker._read_local_file(abs_path: str) -> str {
    try {
        f = open(abs_path, "r", encoding="utf-8");
        out = str(f.read());
        f.close();
        return out;
    } except Exception as e { # jac:ignore[W2052]
        print(f"read_local_file failed for {abs_path}: {e}");
        return "";
    }
}

impl GraphBuilderWalker._import_targets(path: str, language: str, content: str) -> list[str] {
    imported_paths: list[str] = [];
    if language == "python" {
        try {
            pytree = parse(content);
        } except Exception { # jac:ignore[W2052]
            return imported_paths;
        }
        for astn in walk(pytree) {
            if isinstance(astn, AstImport) {
                for alias in astn.names {
                    imported_paths.append(str(alias.name).replace(".", "/") + ".py");
                }
            }
            if isinstance(astn, ImportFrom) and astn.module {
                imported_paths.append(str(astn.module).replace(".", "/") + ".py");
            }
        }
        return imported_paths;
    }
    if language == "jac" {
        mods = findall(r"(?:^|\n)\s*(?:cl\s+)?import\s+from\s+([.@A-Za-z0-9_]+)", content);
        for mod in mods {
            for cand in self._jac_module_to_paths(path, str(mod)) {
                imported_paths.append(cand);
            }
        }
    }
    return imported_paths;
}

impl GraphBuilderWalker._jac_module_to_paths(source_path: str, module_path: str) -> list[str] {
    if not module_path or module_path.startswith("@") {
        return [];
    }
    src_dir = dirname(source_path).replace("\\", "/");
    dots = 0;
    while dots < len(module_path) and module_path[dots] == "." {
        dots += 1;
    }
    rel_mod = module_path[dots:];
    base_dir = src_dir;
    if dots > 1 {
        steps_up = dots - 1;
        parts = [p for p in src_dir.split("/") if p];
        keep = len(parts) - steps_up;
        if keep < 0 {
            keep = 0;
        }
        base_dir = "/".join(parts[:keep]);
    }
    mod_rel = rel_mod.replace(".", "/");
    joined = mod_rel;
    if base_dir and mod_rel {
        joined = base_dir + "/" + mod_rel;
    } elif base_dir {
        joined = base_dir;
    }
    normed = normpath(joined if joined else mod_rel).replace("\\", "/");
    if normed == "." {
        normed = "";
    }
    out: list[str] = [];
    if normed {
        out.append(normed + ".jac");
        out.append(normed + ".cl.jac");
    }
    return out;
}

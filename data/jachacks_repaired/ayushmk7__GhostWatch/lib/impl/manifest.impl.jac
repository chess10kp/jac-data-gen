# lib/impl/manifest.impl.jac

import from json { loads as json_loads, dumps as json_dumps }
import from re { sub as re_sub }

impl normalize_package_name(name: str) -> str {
    n0 = name.strip().lower();
    n1 = re_sub(r"[-_.]+", "-", n0);
    n2 = re_sub(r"[^a-z0-9@-]", "", n1.replace("@", "/"));
    return n2;
}

impl dedupe_incident_key(
    repo_full_name: str,
    commit_sha: str,
    manifest_path: str,
    dependency_name: str
) -> str {
    return f"{repo_full_name}|{commit_sha}|{manifest_path}|{normalize_package_name(dependency_name)}";
}

impl package_alias_map() -> dict {
    return {
        "pil": "pillow",
        "yaml": "pyyaml",
        "sklearn": "scikit-learn",
        "gitpython": "gitpython"
    };
}

impl apply_package_alias(norm: str) -> str {
    m = package_alias_map();
    return m.get(norm, norm);
}

impl parse_package_json_deps(content: str) -> dict {
    if not content.strip() {
        return {};
    }
    data = json_loads(content);
    out = {};
    for section in ["dependencies", "devDependencies", "optionalDependencies", "peerDependencies"] {
        block = data.get(section, {});
        if isinstance(block, dict) {
            for (k, v) in block.items() {
                if isinstance(k, str) {
                    out[k] = str(v) if v is not None else "";
                }
            }
        }
    }
    return out;
}

impl requirements_line_pkg(line: str) -> str {
    s = line.strip();
    a = str(s.split("==")[0]);
    b = str(a.split(">=")[0]);
    c0 = str(b.split("<=")[0]);
    return re_sub(r"\[.*$", "", c0).strip();
}

impl parse_requirements_txt_deps(content: str) -> dict {
    out = {};
    for raw in content.splitlines() {
        line = raw.strip();
        if not line or line.startswith("#") {
            continue;
        }
        if line.startswith("-r ") or line.startswith("--") {
            continue;
        }
        pkg = requirements_line_pkg(line);
        if pkg {
            out[pkg] = line;
        }
    }
    return out;
}

impl parse_toml_deps(content: str) -> dict {
    out = {};
    in_jac_deps = False;
    in_project_deps = False;
    for raw in content.splitlines() {
        line = raw.strip();
        if line == "[dependencies]" {
            in_jac_deps = True;
            in_project_deps = False;
            continue;
        }
        if line == "[project]" {
            in_jac_deps = False;
            in_project_deps = False;
            continue;
        }
        if line == "[project.dependencies]" {
            in_project_deps = True;
            in_jac_deps = False;
            continue;
        }
        if line.startswith("[") {
            in_jac_deps = False;
            in_project_deps = False;
            continue;
        }
        if (in_jac_deps or in_project_deps) and "=" in line and not line.startswith("#") {
            key = line.split("=")[0].strip();
            rest = line.split("=", 1)[1].strip();
            if key == "npm" or key.startswith("dependencies.") {
                continue;
            }
            if key.startswith("\"") {
                continue;
            }
            val = rest.strip("\"'");
            if key and val {
                out[key] = val;
            }
        }
    }
    return out;
}

impl parse_manifest_deps(manifest_path: str, content: str) -> dict {
    p = manifest_path.lower();
    if p.endswith("package.json") {
        return parse_package_json_deps(content);
    }
    if p.endswith("requirements.txt") {
        return parse_requirements_txt_deps(content);
    }
    if p.endswith("pyproject.toml") or p.endswith("jac.toml") {
        return parse_toml_deps(content);
    }
    return {};
}

impl manifest_delta(parent_deps: dict, current_deps: dict) -> dict {
    added = {};
    removed = {};
    for (k, v) in current_deps.items() {
        if k not in parent_deps or parent_deps[k] != v {
            added[k] = v;
        }
    }
    for (k, v) in parent_deps.items() {
        if k not in current_deps {
            removed[k] = v;
        }
    }
    return {"added": added, "removed": removed};
}

impl package_json_scripts_changed(parent_content: str, current_content: str) -> bool {
    try {
        p = json_loads(parent_content) if parent_content.strip() else {};
        c = json_loads(current_content) if current_content.strip() else {};
    } except Exception {
        return False;
    }
    if not isinstance(p, dict) or not isinstance(c, dict) {
        return False;
    }
    ps = p.get("scripts", {});
    cs = c.get("scripts", {});
    if not isinstance(ps, dict) {
        ps = {};
    }
    if not isinstance(cs, dict) {
        cs = {};
    }
    for k in ["postinstall", "preinstall", "install", "prepare"] {
        if ps.get(k, "") != cs.get(k, "") {
            if cs.get(k, "") {
                return True;
            }
        }
    }
    return False;
}

impl pypi_publish_age_days(package_name: str) -> int {
    return -1;
}

impl no_provenance_spec(version_spec: str) -> bool {
    s = str(version_spec).lower();
    if "git+" in s or "github.com" in s or "http://" in s or "file:" in s {
        return True;
    }
    return False;
}

impl importing_normalized_names_from_graph(import_edges_sources: list[str]) -> set {
    out = set();
    for s in import_edges_sources {
        out.add(apply_package_alias(normalize_package_name(s)));
    }
    return out;
}

impl classify_dependency_risks(
    manifest_path: str,
    parent_content: str,
    current_content: str,
    added_deps: dict,
    graph_imports_normalized: set[str]
) -> list[dict] {
    results = [];
    postinstall = False;
    if manifest_path.lower().endswith("package.json") {
        postinstall = package_json_scripts_changed(parent_content, current_content);
    }
    for (name, ver) in added_deps.items() {
        norm = apply_package_alias(normalize_package_name(name));
        rules = [];
        if norm not in graph_imports_normalized and len(graph_imports_normalized) > 0 {
            rules.append("phantom_import");
        }
        if postinstall {
            rules.append("new_postinstall");
        }
        age = pypi_publish_age_days(name);
        if age >= 0 and age < 30 {
            if not manifest_path.lower().endswith("package.json") {
                rules.append("young_package");
            }
        }
        if manifest_path.lower().endswith("package.json") {
            if isinstance(ver, str) and ("*" in ver or "latest" == ver.lower()) {
                rules.append("no_provenance");
            }
        }
        if no_provenance_spec(ver) {
            rules.append("no_provenance");
        }
        if not rules {
            continue;
        }
        risk = "medium";
        if ("phantom_import" in rules) and ("new_postinstall" in rules) {
            risk = "critical";
        } elif len([r for r in rules if r in ["phantom_import", "new_postinstall", "no_provenance"]]) >= 2 {
            risk = "high";
        } elif len(rules) >= 2 {
            risk = "high";
        }
        results.append(
            {
                "name": name,
                "version": str(ver),
                "manifest_path": manifest_path,
                "rule_codes": rules,
                "risk_level": risk
            }
        );
    }
    return results;
}

impl fix_invert_manifest(
    manifest_path: str,
    parent_content: str,
    current_content: str,
    dependency_name: str
) -> str {
    p = manifest_path.lower();
    if p.endswith("package.json") {
        try {
            par_raw = json_loads(parent_content) if parent_content.strip() else {};
            cur_raw = json_loads(current_content) if current_content.strip() else {};
        } except Exception {
            return current_content;
        }
        if not isinstance(par_raw, dict) or not isinstance(cur_raw, dict) {
            return current_content;
        }
        par = par_raw;
        cur = cur_raw;
        for section in ["dependencies", "devDependencies", "optionalDependencies", "peerDependencies"] {
            cur_sec = cur.get(section);
            if not isinstance(cur_sec, dict) {
                continue;
            }
            if dependency_name not in cur_sec {
                continue;
            }
            par_sec = par.get(section);
            if isinstance(par_sec, dict) and dependency_name in par_sec {
                cur_sec[dependency_name] = par_sec[dependency_name];
            } else {
                del cur_sec[dependency_name];
            }
        }
        par_scripts = par.get("scripts");
        cur_scripts = cur.get("scripts");
        if isinstance(par_scripts, dict) and isinstance(cur_scripts, dict) {
            for k in ["postinstall", "preinstall", "install", "prepare"] {
                if k in par_scripts {
                    cur_scripts[k] = par_scripts[k];
                } elif k in cur_scripts {
                    del cur_scripts[k];
                }
            }
        }
        return json_dumps(cur, indent=2);
    }
    if p.endswith("requirements.txt") {
        parent_lines = [];
        for line in parent_content.splitlines() {
            if line.strip() and not line.strip().startswith("#") {
                parent_lines.append(line);
            }
        }
        dep_norm = normalize_package_name(dependency_name);
        cur_lines = [];
        for line in current_content.splitlines() {
            stripped = line.strip();
            if not stripped or stripped.startswith("#") {
                cur_lines.append(line);
                continue;
            }
            pkg = requirements_line_pkg(stripped);
            if normalize_package_name(pkg) == dep_norm {
                repl = None;
                for pl in parent_lines {
                    pp = requirements_line_pkg(pl);
                    if normalize_package_name(pp) == dep_norm {
                        repl = pl;
                        break;
                    }
                }
                if repl {
                    cur_lines.append(repl);
                }
            } else {
                cur_lines.append(line);
            }
        }
        return "\n".join(cur_lines) + ("\n" if cur_lines else "");
    }
    if p.endswith("pyproject.toml") or p.endswith("jac.toml") {
        return parent_content;
    }
    return current_content;
}

impl impl_likely_has_conventional_test(impl_path: str, test_file_paths: set[str]) -> bool {
    parts = str(impl_path).split("/");
    base = parts[-1] if parts else str(impl_path);
    if not base or "." not in base {
        return False;
    }
    stem_ext = base.rsplit(".", 1);
    if len(stem_ext) < 2 {
        return False;
    }
    stem = stem_ext[0];
    ext = stem_ext[1];
    expected = "test_" + stem + "." + ext;
    for tp in test_file_paths {
        tps = str(tp);
        if tps.endswith("/" + expected) or tps == expected {
            return True;
        }
    }
    return False;
}

impl rank_gap_candidates(
    file_paths: list[str],
    paths_with_tests: set[str],
    paths_with_docs: set[str],
    core_prefixes: list[str]
) -> list[dict] {
    scored = [];
    for fp in file_paths {
        low = fp.lower();
        if "test" in low or low.endswith("_test.py") or low.startswith("tests/") {
            continue;
        }
        if not (low.endswith(".jac") or low.endswith(".py")) {
            continue;
        }
        score = 0;
        in_core = any(fp.startswith(pref) for pref in core_prefixes);
        if in_core {
            score += 3;
        }
        if not impl_likely_has_conventional_test(fp, paths_with_tests) {
            score += 5;
        }
        if low.endswith(".jac") and fp not in paths_with_docs {
            score += 4;
        }
        if score > 0 {
            scored.append({"path": fp, "score": score});
        }
    }
    for i in range(len(scored)) {
        for j in range(i + 1, len(scored)) {
            if int(scored[j].get("score", 0)) > int(scored[i].get("score", 0)) {
                tmp = scored[i];
                scored[i] = scored[j];
                scored[j] = tmp;
            }
        }
    }
    return scored[:25];
}

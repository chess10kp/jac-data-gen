"""Deterministic npm manifest parsers (package-lock.json and package.json)."""

import from tools.jac_coerce { as_list }
import from tools.risk_scorer { filter_top_risk_packages }

sem parse_npm_lockfile = "Parse package-lock JSON into packages and dependency edges.";
sem parse_npm_package_json = "Parse package.json direct dependencies into a shallow graph.";

def _normalize_version_spec(spec: str) -> str {
    s = str(spec).strip();
    if not s or s == "*" {
        return "";
    }
    if s.startswith("^") {
        s = s[1:].strip();
    } elif s.startswith("~") {
        s = s[1:].strip();
    } elif s.startswith(">=") {
        s = s[2:].strip();
    } elif s.startswith("<=") {
        s = s[2:].strip();
    } elif s.startswith(">") {
        s = s[1:].strip();
    } elif s.startswith("<") {
        s = s[1:].strip();
    } elif s.startswith("=") {
        s = s[1:].strip();
    }
    if "||" in s {
        s = s.split("||", 1)[0].strip();
    }
    if " - " in s {
        parts = s.split(" - ");
        s = parts[-1].strip();
    }
    return s;
}

def parse_npm_package_json(manifest_text: str) -> dict {
    import json;

    try {
        data = json.loads(manifest_text);
    } except Exception as e {
        return {"ok": False, "error": f"Invalid JSON: {e}"};
    }
    if not isinstance(data, dict) {
        return {"ok": False, "error": "package.json root must be an object"};
    }

    root_name = str(data.get("name", "root"));
    root_version = _normalize_version_spec(str(data.get("version", "0.0.0")));
    if not root_version {
        root_version = "0.0.0";
    }
    root_key = f"{root_name}@{root_version}";

    packages: list[dict] = [
        {
            "key": root_key,
            "name": root_name,
            "version": root_version,
            "is_direct": True,
            "depth": 0,
            "lock_path": ""
        }
    ];
    edges: list[dict] = [];
    deps = data.get("dependencies", {});
    if not isinstance(deps, dict) {
        deps = {};
    }

    dep_keys = list(deps.keys());
    for dep_name in dep_keys {
        dep_spec = str(deps[dep_name]);
        dep_version = _normalize_version_spec(dep_spec);
        if not dep_version {
            dep_version = dep_spec;
        }
        dep_key = f"{dep_name}@{dep_version}";
        packages.append(
            {
                "key": dep_key,
                "name": str(dep_name),
                "version": dep_version,
                "is_direct": True,
                "depth": 1,
                "lock_path": f"node_modules/{dep_name}"
            }
        );
        edges.append(
            {
                "from_key": root_key,
                "to_key": dep_key,
                "required_version": dep_spec
            }
        );
    }

    if len(packages) <= 1 {
        return {
            "ok": False,
            "error": "package.json has no dependencies field entries"
        };
    }

    return {
        "ok": True,
        "packages": packages,
        "edges": edges,
        "package_count": len(packages),
        "manifest_kind": "package_json"
    };
}

def _lock_path_name(lock_path: str) -> str {
    if lock_path == "" {
        return "";
    }
    if lock_path.startswith("node_modules/") {
        return lock_path.split("node_modules/")[-1];
    }
    return lock_path;
}

def parse_npm_lockfile(
    lock_text: str,
    max_packages: int = 200
) -> dict {
    import json;

    try {
        data = json.loads(lock_text);
    } except Exception as e {
        return {"ok": False, "error": f"Invalid JSON: {e}"};
    }
    raw_packages = data.get("packages", {});
    if not raw_packages {
        return {
            "ok": False,
            "error": "No packages field — need package-lock.json v2/v3"
        };
    }

    packages: list[dict] = [];
    edges: list[dict] = [];
    index: dict = {};
    name_to_key: dict = {};

    lock_paths = list(raw_packages.keys());
    for lock_path in lock_paths {
        lock_path_str: str = str(lock_path);
        meta = raw_packages[lock_path];
        if not isinstance(meta, dict) {
            continue;
        }
        version = meta.get("version", "");
        if not version {
            continue;
        }
        name = meta.get("name", _lock_path_name(lock_path_str));
        if not name {
            continue;
        }
        key = f"{name}@{version}";
        is_direct = False;
        if lock_path_str == "" {
            is_direct = True;
        } elif lock_path_str.startswith("node_modules/") {
            rest: str = str(lock_path_str.removeprefix("node_modules/"));
            is_direct = "/" not in rest;
        }
        depth = 0;
        if lock_path_str != "" {
            depth = lock_path_str.count("node_modules/");
        }
        if key not in index {
            index[key] = len(packages);
            name_to_key[str(name)] = key;
            packages.append(
                {
                    "key": key,
                    "name": name,
                    "version": version,
                    "is_direct": is_direct,
                    "depth": depth,
                    "lock_path": lock_path_str
                }
            );
        }
    }

    for lock_path in lock_paths {
        lock_path_str: str = str(lock_path);
        meta = raw_packages[lock_path];
        if not isinstance(meta, dict) {
            continue;
        }
        from_version = meta.get("version", "");
        if not from_version {
            continue;
        }
        from_name = meta.get("name", _lock_path_name(lock_path_str));
        if not from_name {
            continue;
        }
        from_key = f"{from_name}@{from_version}";
        if from_key not in index {
            continue;
        }
        deps = meta.get("dependencies", {});
        if not isinstance(deps, dict) {
            continue;
        }
        dep_keys = list(deps.keys());
        for dep_name in dep_keys {
            dep_spec = deps[dep_name];
            dep_str = str(dep_name);
            to_key = "";
            if dep_str in name_to_key {
                to_key = name_to_key[dep_str];
            }
            if not to_key {
                continue;
            }
            edges.append(
                {
                    "from_key": from_key,
                    "to_key": to_key,
                    "required_version": str(dep_spec)
                }
            );
        }
    }

    filtered = filter_top_risk_packages(packages, edges, max_packages);
    final_packages = as_list(filtered["packages"]);
    final_edges = as_list(filtered["edges"]);

    return {
        "ok": True,
        "packages": final_packages,
        "edges": final_edges,
        "package_count": len(final_packages),
        "truncated": filtered["truncated"],
        "original_package_count": filtered["original_package_count"],
        "filter_method": filtered["method"]
    };
}

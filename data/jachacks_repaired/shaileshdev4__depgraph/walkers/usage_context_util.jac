"""Usage context attachment and exploitability helpers."""

import from ..graph.nodes { Package, UsageContext }
import from ..graph.edges { DependsOn }
import from ..tools.github_api {
    parse_github_repo_url,
    search_github_package_imports
}
import from ..tools.jac_coerce { as_list }
import from walkers.extract_walker { classify_usage_from_paths }
import from ..tools.investigation_runner { session_push }

def _usage_surface_rank(surface: str) -> int {
    s = str(surface).lower();
    if s == "production" {
        return 4;
    }
    if s == "mixed" {
        return 3;
    }
    if s == "build" {
        return 2;
    }
    if s == "test" {
        return 1;
    }
    return 0;
}

def package_usage_surface(pkg_node: Package) -> str {
    best_surface = "unknown";
    best_rank = 0;
    for ctx_node in [pkg_node-->][?:UsageContext] {
        surface = str(ctx_node.risk_surface);
        if not surface {
            continue;
        }
        rank = _usage_surface_rank(surface);
        if rank > best_rank {
            best_rank = rank;
            best_surface = surface;
        }
    }
    return best_surface;
}

def compute_exploitability(max_cvss: float, usage_surface: str) -> str {
    surface = str(usage_surface).lower();
    if max_cvss >= 7.0 and surface == "production" {
        return "CRITICAL";
    }
    if max_cvss >= 4.0 and surface == "production" {
        return "HIGH";
    }
    if surface == "test" {
        return "LOW";
    }
    return "MEDIUM";
}

# Root package.json name (depth 0) is not a third-party dependency.
def is_workspace_package(pkg_node: Package, repo_url: str) -> bool {
    if pkg_node.depth == 0 {
        return True;
    }
    parsed = parse_github_repo_url(repo_url);
    if parsed["ok"] {
        repo_nm = str(parsed["repo"]).lower();
        if repo_nm and str(pkg_node.name).lower() == repo_nm {
            return True;
        }
    }
    return False;
}

def package_has_usage_context(pkg_node: Package) -> bool {
    return _usage_surface_rank(package_usage_surface(pkg_node)) > 0;
}

def inherit_usage_from_importers(
    pkg_node: Package,
    session_packages: list[Package]
) -> dict {
    found_prod = False;
    found_test = False;
    inherited_from: list[str] = [];
    for other in session_packages {
        for dep in [other ->:DependsOn:->][?:Package] {
            if dep.name != pkg_node.name {
                continue;
            }
            if other.name in inherited_from {
                continue;
            }
            inherited_from.append(other.name);
            surface = package_usage_surface(other);
            if surface == "production" {
                found_prod = True;
            } elif surface == "test" {
                found_test = True;
            }
        }
    }
    if found_prod {
        return {
            "surface": "production",
            "is_prod": True,
            "importing_file_count": 0,
            "importing_files": [],
            "inherited_from": inherited_from
        };
    }
    if found_test {
        return {
            "surface": "test",
            "is_prod": False,
            "importing_file_count": 0,
            "importing_files": [],
            "inherited_from": inherited_from
        };
    }
    return {};
}

def refresh_findings_usage(
    findings: list[dict],
    session_packages: list[Package]
) -> None {
    for item in findings {
        pkg_name = str(item["package"]);
        pkg_version = str(item["version"]);
        for pkg_node in session_packages {
            if pkg_node.name != pkg_name {
                continue;
            }
            if str(pkg_node.version) != pkg_version {
                continue;
            }
            surface = package_usage_surface(pkg_node);
            item["usage_surface"] = surface;
            cvss_val = 0.0;
            if "max_cvss" in item {
                cvss_val = float(str(item["max_cvss"]));
            }
            item["exploitability"] = compute_exploitability(
                cvss_val,
                surface
            );
            import_count = 0;
            for ctx_node in [pkg_node-->][?:UsageContext] {
                files = ctx_node.called_from_modules;
                if isinstance(files, list) {
                    import_count = len(files);
                }
            }
            if import_count == 0 or surface == "unknown" {
                inherited = inherit_usage_from_importers(
                    pkg_node,
                    session_packages
                );
                if inherited and "surface" in inherited {
                    inh_surface = str(inherited["surface"]);
                    if _usage_surface_rank(inh_surface) > _usage_surface_rank(surface) {
                        item["usage_surface"] = inh_surface;
                        item["exploitability"] = compute_exploitability(
                            cvss_val,
                            inh_surface
                        );
                        surface = inh_surface;
                    }
                    if "inherited_from" in inherited {
                        raw_from = inherited["inherited_from"];
                        if isinstance(raw_from, list) {
                            item["usage_inherited_from"] = raw_from;
                        }
                    }
                }
            }
            break;
        }
    }
}

def attach_usage_context_for_package(
    repo_url: str,
    pkg_node: Package,
    session_id: str,
    session_packages: list[Package]
) -> None {
    if package_has_usage_context(pkg_node) {
        return;
    }
    if is_workspace_package(pkg_node, repo_url) {
        return;
    }
    paths = search_github_package_imports(
        repo_url,
        pkg_node.name,
        pkg_node.ecosystem
    );
    inherited_from: list[str] = [];
    if paths {
        ctx = classify_usage_from_paths(
            pkg_node.name,
            paths,
            pkg_node.ecosystem
        );
    } else {
        inherited = inherit_usage_from_importers(
            pkg_node,
            session_packages
        );
        if inherited and "surface" in inherited {
            ctx = inherited;
            if "inherited_from" in inherited {
                for nm in as_list(inherited["inherited_from"]) {
                    inherited_from.append(str(nm));
                }
            }
        } else {
            ctx = {
                "surface": "unknown",
                "is_prod": False,
                "importing_file_count": 0,
                "importing_files": [],
            };
        }
    }
    usage_surface = str(ctx["surface"]);
    is_prod = bool(ctx["is_prod"]);
    import_files = ctx["importing_files"];
    if not isinstance(import_files, list) {
        import_files = [];
    }
    usage_node = UsageContext(
        risk_surface=usage_surface,
        is_reachable_in_prod=is_prod,
        called_from_modules=import_files
    );
    pkg_node ++> usage_node;
    usage_report = {
        "event": "usage_context",
        "package": pkg_node.name,
        "version": pkg_node.version,
        "surface": usage_surface,
        "risk_surface": usage_surface,
        "is_prod": is_prod,
        "is_reachable_in_prod": is_prod,
        "importing_file_count": ctx["importing_file_count"],
        "importing_files": import_files,
        "import_file_count": ctx["importing_file_count"],
        "inherited_from": inherited_from
    };
    report usage_report;
    if session_id {
        session_push(session_id, usage_report);
    }
}

def push_live_event(session_id: str, payload: dict) -> None {
    if session_id {
        session_push(session_id, payload);
    }
}

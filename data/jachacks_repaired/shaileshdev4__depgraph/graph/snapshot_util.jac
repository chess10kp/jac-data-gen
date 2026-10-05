"""Build graph_snapshot payloads for the React canvas."""

import from graph.nodes { Package, CVE }
import from ..tools.jac_coerce { as_list }
import from ..tools.risk_scorer { package_risk_score }

def pkg_node_id(name: str, version: str) -> str {
    return f"{name}@{version}";
}

def severity_from_cvss(cvss: float) -> str {
    if cvss >= 9.0 {
        return "CRITICAL";
    }
    if cvss >= 7.0 {
        return "HIGH";
    }
    if cvss >= 4.0 {
        return "MEDIUM";
    }
    if cvss > 0.0 {
        return "LOW";
    }
    return "CLEAN";
}

def build_graph_snapshot(
    session_packages: list[Package],
    parsed: dict,
    spawn_root_ids: list[str]
) -> dict {
    pkg_list: list = as_list(parsed.get("packages", []));
    dep_edges: list = as_list(parsed.get("edges", []));
    key_to_id: dict = {};
    for pkg in pkg_list {
        kid = pkg_node_id(str(pkg["name"]), str(pkg["version"]));
        key_to_id[str(pkg["key"])] = kid;
    }

    spawn_set: dict = {};
    for sid in spawn_root_ids {
        spawn_set[sid] = True;
    }

    nodes: list[dict] = [];
    for pkg_node in session_packages {
        nid = pkg_node_id(pkg_node.name, pkg_node.version);
        cve_cnt = 0;
        max_cvss = pkg_node.cvss_score;
        for cve_node in [pkg_node-->][?:CVE] {
            cve_cnt += 1;
            if cve_node.cvss_score > max_cvss {
                max_cvss = cve_node.cvss_score;
            }
        }
        nodes.append(
            {
                "id": nid,
                "name": pkg_node.name,
                "version": pkg_node.version,
                "depth": pkg_node.depth,
                "is_direct": pkg_node.is_direct,
                "risk_score": package_risk_score(
                    pkg_node.name,
                    pkg_node.version,
                    pkg_node.depth,
                    pkg_node.is_direct
                ),
                "cvss_score": max_cvss,
                "cve_count": cve_cnt,
                "is_spawn_root": nid in spawn_set,
                "severity": severity_from_cvss(max_cvss)
            }
        );
    }

    edges: list[dict] = [];
    for edge in dep_edges {
        fk = str(edge.get("from_key", ""));
        tk = str(edge.get("to_key", ""));
        if fk in key_to_id and tk in key_to_id {
            edges.append(
                {
                    "source": key_to_id[fk],
                    "target": key_to_id[tk],
                    "type": "depends_on"
                }
            );
        }
    }

    return {"nodes": nodes, "edges": edges};
}

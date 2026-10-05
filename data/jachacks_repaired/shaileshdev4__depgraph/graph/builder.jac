"""Build Package nodes and DependsOn edges on the investigation graph."""

import from graph.nodes { InvestigationSession, Package }
import from graph.edges { DependsOn }
import from ..tools.jac_coerce { as_list }

def build_package_graph(session: InvestigationSession, parsed: dict) -> int {
    pkg_list: list = as_list(parsed.get("packages", []));
    dep_edges: list = as_list(parsed.get("edges", []));

    node_by_key: dict = {};

    for pkg in pkg_list {
        key = pkg["key"];
        pkg_node = Package(
            name=pkg["name"],
            version=pkg["version"],
            ecosystem=session.ecosystem,
            is_direct=pkg["is_direct"],
            depth=pkg["depth"],
            analysis_status="pending"
        );
        session ++> pkg_node;
        node_by_key[key] = pkg_node;
    }

    for edge in dep_edges {
        from_node = node_by_key.get(edge["from_key"], None);
        to_node = node_by_key.get(edge["to_key"], None);
        if from_node and to_node {
            req: str = str(edge["required_version"]);
            from_node
                +>:DependsOn(required_version=req):+>
                to_node;
        }
    }

    cnt = 0;
    for _p in pkg_list {
        cnt += 1;
    }
    return cnt;
}

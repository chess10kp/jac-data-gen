# walkers/static/impl/blast_radius.impl.jac

import from graph.nodes { FileNode }

impl BlastRadiusMapperWalker.start_from_root with Root entry {
    visit [-->][?:FileNode];
}

impl BlastRadiusMapperWalker.map_blast with FileNode entry {
    is_changed = here.path in self.changed_nodes;
    is_affected = self.current_hop > 0;

    if not is_changed and not is_affected {
        visit [-->][?:FileNode];
        return;
    }
    if here.path in self.affected_nodes {
        return;
    }
    self.affected_nodes.append(here.path);
    self.traversal_path.append(jid(here));

    try {
        node_score = self._score_node(  # jac:ignore[W2001]
            node_path=here.path,
            node_language=here.language,
            hop_distance=self.current_hop
        );
        here.risk_score = node_score;
        self.risk_score += node_score;
    } except Exception as e { # jac:ignore[W2052]
        print(f"BlastRadius score failed for {here.path}: {e}");
        here.risk_score = max(0, 10 - self.current_hop * 2);
        self.risk_score += here.risk_score;
    }

    if self.current_hop < self.max_hops {
        self.current_hop += 1;
        visit [-->][?:FileNode];
        self.current_hop -= 1;
    }

    report {
        "affected_nodes": self.affected_nodes,
        "risk_score": self.risk_score,
        "traversal_path": self.traversal_path,
        "affected_count": len(self.affected_nodes)
    };
}

impl BlastRadiusMapperWalker._severity_from_hops(hops: int) -> str {
    if hops == 0 {
        return "critical";
    } elif hops == 1 {
        return "high";
    } elif hops == 2 {
        return "medium";
    } else {
        return "low";
    }
}

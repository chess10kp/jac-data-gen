# walkers/static/blast_radius.jac

import from graph.nodes { FileNode }

walker BlastRadiusMapperWalker {
    has changed_nodes: list[str] = [];
    has affected_nodes: list[str] = [];
    has max_hops: int = 5;
    has current_hop: int = 0;
    has risk_score: int = 0;
    has traversal_path: list[str] = [];

    can start_from_root with Root entry;
    can map_blast with FileNode entry;

    def _score_node(node_path: str, node_language: str, hop_distance: int) -> int by llm;

    def _severity_from_hops(hops: int) -> str;
}

sem BlastRadiusMapperWalker._score_node = "Return an integer 0-20 representing how risky this node is at this hop distance. Higher scores for core files, lower for test/doc files and farther hops."; # jac:ignore[W2001]

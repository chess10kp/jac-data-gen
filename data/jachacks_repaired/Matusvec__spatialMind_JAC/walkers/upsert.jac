# Instance upsert walker -- merges query nodes into the persistent graph.
# Replaces server/services/instance_cache.py's upsert_query_nodes() and
# build_instance_graph(). Takes query_nodes from Python compute, walks
# existing SceneObject nodes, checks overlap, creates/merges, then
# creates spatial edges.

import from graph.types {
    SceneRoot, SceneObject, SpatialRelation, SemanticHierarchy, Contains
}
import from services.py_bridge { get_state }
import from server.services.instance_cache {
    upsert_query_nodes, build_instance_graph
}

# Upsert query results into the JAC scene graph.
walker UpsertInstances {
    has query_text: str;
    has query_nodes: list = [];

    can upsert with SceneRoot entry {
        state = get_state();
        gs = state.get("gaussian_store");
        store = state.get("instance_store");

        if not self.query_nodes or store is None {
            report {"upserted": 0};
            return;
        }

        # Use Python's upsert logic (heavy numpy geometry)
        persisted = upsert_query_nodes(
            store, self.query_nodes, gs,
            query_text=self.query_text
        );

        # Rebuild the instance graph
        graph = build_instance_graph(store, gs);
        state["instance_graph"] = graph;

        # Sync JAC graph: remove old objects and recreate
        old_objects = [-->];
        for old_item in old_objects {
            del old_item;
        }

        # Create new SceneObject nodes from instance graph
        for node_dict in graph.get("nodes", []) {
            scene_obj = SceneObject(
                id=node_dict["id"],
                label=node_dict.get("label", "region"),
                centroid=node_dict.get("centroid", [0, 0, 0]),
                bbox=node_dict.get("bbox", [0] * 6),
                gaussian_indices=node_dict.get("gaussian_indices", []),
                confidence=node_dict.get("confidence", 0.0),
                match_score=node_dict.get("match_score", 0.0),
                radius=node_dict.get("radius", 0.15),
                aliases=node_dict.get("aliases", []),
                query_count=node_dict.get("query_count", 0)
            );
            here ++> Contains ++> scene_obj;
        }

        # Create spatial edges between objects
        all_objects = [-->];
        node_map = {};
        for so in all_objects {
            node_map[so.id] = so;
        }
        for edge_dict in graph.get("edges", []) {
            src = node_map.get(edge_dict.get("from", ""));
            dst = node_map.get(edge_dict.get("to", ""));
            if src and dst {
                src +>:SpatialRelation(
                    relation=edge_dict.get("relation", "next_to"),
                    confidence=edge_dict.get("confidence", 0.0),
                    distance=edge_dict.get("distance", 0.0)
                ):+> dst;
            }
        }

        # Create hierarchy edges
        for h_dict in graph.get("hierarchy", []) {
            src = node_map.get(h_dict.get("from", ""));
            dst = node_map.get(h_dict.get("to", ""));
            if src and dst {
                src +>:SemanticHierarchy(
                    similarity=h_dict.get("similarity", 0.0)
                ):+> dst;
            }
        }

        report {
            "upserted": len(persisted),
            "total_instances": len(graph.get("nodes", [])),
            "edges": len(graph.get("edges", []))
        };
    }
}

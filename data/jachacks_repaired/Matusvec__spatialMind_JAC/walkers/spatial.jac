# Spatial relation builder walker.

import from graph.types {
    SceneRoot, SceneObject, SpatialRelation, SemanticHierarchy
}
import from services.py_bridge { get_state }
import from server.services.spatial_relations { extract_spatial_relations, build_hierarchy }
import numpy as np;

# Rebuild spatial edges between all SceneObject nodes.
walker BuildSpatialRelations {
    can build with SceneRoot entry {
        objects = [-->];
        if not objects {
            report {"edges_created": 0};
            return;
        }

        state = get_state();
        gs = state.get("gaussian_store");

        clusters = [];
        for item in enumerate(objects) {
            idx = item[0];
            scene_obj = item[1];
            mean_emb = np.zeros(512, dtype=np.float32);
            if gs and hasattr(gs, "decoded_embeddings") and gs.decoded_embeddings is not None {
                indices = np.asarray(scene_obj.gaussian_indices, dtype=np.int64);
                valid = indices[(indices >= 0) & (indices < len(gs.decoded_embeddings))];
                if len(valid) > 0 {
                    emb = gs.decoded_embeddings[valid].mean(axis=0).astype(np.float32);
                    norm_val = float(np.linalg.norm(emb));
                    if norm_val > 1e-8 {
                        mean_emb = emb / norm_val;
                    }
                }
            }
            clusters.append({
                "label": idx,
                "centroid": scene_obj.centroid,
                "bbox": scene_obj.bbox,
                "mean_embedding": mean_emb
            });
        }

        raw_edges = extract_spatial_relations(clusters);
        raw_hierarchy = build_hierarchy(
            [c for c in clusters if np.any(c["mean_embedding"])],
            similarity_threshold=0.72
        );

        edge_count = 0;
        for edge_dict in raw_edges {
            src = objects[edge_dict["from_label"]];
            dst = objects[edge_dict["to_label"]];
            src +>:SpatialRelation(
                relation=edge_dict["relation"],
                confidence=edge_dict["confidence"],
                distance=edge_dict["distance"]
            ):+> dst;
            edge_count += 1;
        }

        for h_dict in raw_hierarchy {
            src = objects[h_dict["from_label"]];
            dst = objects[h_dict["to_label"]];
            src +>:SemanticHierarchy(
                similarity=h_dict["similarity"]
            ):+> dst;
        }

        report {
            "edges_created": edge_count,
            "hierarchy_created": len(raw_hierarchy)
        };
    }
}

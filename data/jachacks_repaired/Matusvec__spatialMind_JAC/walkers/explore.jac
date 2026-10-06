# Exploration walker -- catalogs all objects in the scene graph.
# Replaces server/services/exploration_walker.py (133 lines) and
# walker_base.py (146 lines). JAC handles graph traversal natively.

import from graph.types { SceneRoot, SceneObject, SpatialRelation, Contains }
import from services.py_bridge { get_state }
import logging;

walker:pub ExploreScene {
    has scene_id: str = "default";
    has force: bool = False;
    has catalog_entries: list = [];

    can start with Root entry {
        scenes = [-->];
        if scenes {
            visit scenes;
        } else {
            state = get_state();
            ig = state.get("instance_graph");
            if ig and ig.get("nodes") {
                report self._build_catalog_from_dict(ig);
            } else {
                report {
                    "catalog": "No objects discovered yet. Run a query first.",
                    "object_count": 0,
                    "scene_id": self.scene_id
                };
            }
        }
    }

    can catalog with SceneRoot entry {
        visit [-->];
        report {
            "catalog": self.format_catalog(),
            "object_count": len(self.catalog_entries),
            "scene_id": self.scene_id
        };
    }

    can collect with SceneObject entry {
        self.catalog_entries.append({
            "id": here.id,
            "label": here.label,
            "centroid": here.centroid,
            "confidence": here.confidence,
            "relationships": []
        });
        visit [-->];
    }

    def format_catalog() -> str {
        count = len(self.catalog_entries);
        lines = [f"Scene Object Catalog ({count} objects):", ""];
        for ent in self.catalog_entries {
            cx = ent["centroid"][0];
            cy = ent["centroid"][1];
            cz = ent["centroid"][2];
            lines.append(
                f"- {ent['label']} ({ent['id']}): "
                + f"located at ({cx:.1f}, {cy:.1f}, {cz:.1f}), "
                + f"confidence {ent['confidence']:.2f}"
            );
            if ent["relationships"] {
                rels = ", ".join(ent["relationships"]);
                lines.append(f"  Relationships: {rels}");
            }
        }
        return "\n".join(lines);
    }

    def _build_catalog_from_dict(ig: dict) -> dict {
        nodes = ig.get("nodes", []);
        edges = ig.get("edges", []);
        lines = [f"Scene Object Catalog ({len(nodes)} objects):", ""];

        for nd in nodes {
            centroid = nd.get("centroid", [0, 0, 0]);
            cx = centroid[0];
            cy = centroid[1];
            cz = centroid[2];
            lines.append(
                f"- {nd.get('label', 'unknown')} ({nd.get('id', '?')}): "
                + f"located at ({cx:.1f}, {cy:.1f}, {cz:.1f}), "
                + f"confidence {nd.get('confidence', 0):.2f}"
            );
            rels = [];
            for edge in edges {
                if edge.get("from") == nd.get("id") {
                    rels.append(f"{edge.get('relation', 'related_to')} {edge.get('to', '?')}");
                } elif edge.get("to") == nd.get("id") {
                    rels.append(f"{edge.get('relation', 'related_to')} {edge.get('from', '?')}");
                }
            }
            if rels {
                lines.append(f"  Relationships: {', '.join(rels)}");
            }
        }

        return {
            "catalog": "\n".join(lines),
            "object_count": len(nodes),
            "scene_id": self.scene_id
        };
    }
}

walker:pub ExploreStatus {
    can check with Root entry {
        state = get_state();
        ig = state.get("instance_graph");

        if ig is None or not ig.get("nodes") {
            report {
                "status": "complete",
                "objects": [],
                "graph": {"nodes": [], "edges": []},
                "progress": 0.0
            };
        } else {
            raw_nodes = ig.get("nodes", []);
            raw_edges = ig.get("edges", []);
            objects = [];
            for item in enumerate(raw_nodes) {
                i = item[0];
                n = item[1];
                objects.append({
                    "id": n.get("id", f"obj_{i:03d}"),
                    "label": n.get("label", "Unknown"),
                    "confidence": n.get("confidence", 0.9),
                    "position": n.get("centroid", [0, 0, 0]),
                    "category": _categorize(n.get("label", ""))
                });
            }
            graph_nodes = [];
            for n in raw_nodes {
                graph_nodes.append({"id": n.get("id", ""), "label": n.get("label", ""), "type": "object"});
            }
            graph_edges = [];
            for e in raw_edges {
                graph_edges.append({
                    "from": e.get("from", ""),
                    "to": e.get("to", ""),
                    "relation": e.get("relation", "related")
                });
            }

            report {
                "status": "complete",
                "objects": objects,
                "graph": {"nodes": graph_nodes, "edges": graph_edges},
                "progress": 1.0
            };
        }
    }
}

def _categorize(label: str) -> str {
    lower = label.lower();
    category_map = {
        "chair": "Furniture", "table": "Furniture", "desk": "Furniture",
        "shelf": "Furniture", "couch": "Furniture", "sofa": "Furniture",
        "monitor": "Electronics", "laptop": "Electronics",
        "lamp": "Lighting", "light": "Lighting",
        "plant": "Decor", "rug": "Decor", "vase": "Decor",
        "window": "Structure", "wall": "Structure", "door": "Structure", "floor": "Structure"
    };
    for item in category_map.items() {
        keyword = item[0];
        cat = item[1];
        if keyword in lower {
            return cat;
        }
    }
    return "Objects";
}

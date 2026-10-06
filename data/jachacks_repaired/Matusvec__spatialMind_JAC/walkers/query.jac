# Query walkers -- natural language scene queries.
# Replaces server/services/query_walker.py (217 lines) and the
# query/highlight/probability endpoints from adapter.py.

import from graph.types { SceneRoot, SceneObject, SpatialRelation, JobStatus }
import from services.py_bridge { get_state }
import from server.services.gemini_agent {
    GeminiSceneAgent, format_dense_payload, gemini_enabled, init_agent_steps
}
import from server.services.dense_query { ground_query }
import from server.services.similarity { probability_cloud as prob_cloud }
import from services.py_bridge { serve_scene_file }
import uuid;
import logging;

glob _query_jobs: dict = {};

def _init_query_steps() -> list {
    steps = [];
    pairs = [
        ["normalize_query", "Normalize query"],
        ["encode_query", "Encode text with CLIP"],
        ["score_semantics", "Score sem2"],
        ["cluster_regions", "Group grounded splats in 3D"],
        ["materialize_instances", "Materialize reusable instances"],
        ["build_graph", "Build instance graph"],
        ["prepare_response", "Prepare highlights and response"]
    ];
    for pair in pairs {
        steps.append({"key": pair[0], "label": pair[1], "status": "pending", "detail": None});
    }
    return steps;
}

# Ground a chat query directly against the dense 3D semantic field.
walker:pub QueryDirect {
    has query: str;
    has mode: str = "query";

    can search with Root entry {
        state = get_state();
        if not self.query.strip() {
            report {"error": "Query must be non-empty."};
            return;
        }

        if gemini_enabled(state) {
            try {
                agent = GeminiSceneAgent(state=state);
                result = agent.run(query=self.query, mode=self.mode);
                report result;
                return;
            } except Exception as exc {
                logger = logging.getLogger("spatialMind");
                logger.warning("Gemini agent failed, falling back: %s", exc);
            }
        }

        result = ground_query(text=self.query, state=state, persist_instances=True);
        payload = format_dense_payload(
            result,
            mode=self.mode,
            query=self.query,
            answer=result.get("answer", "")
        );
        report payload;
    }
}

# Start a query job and return a polling handle.
walker:pub QueryStart {
    has query: str;
    has mode: str = "query";

    can start with Root entry {
        state = get_state();
        if not self.query.strip() {
            report {"error": "Query must be non-empty."};
            return;
        }

        steps = init_agent_steps() if gemini_enabled(state) else _init_query_steps();
        job_id = uuid.uuid4().hex;
        _query_jobs[job_id] = {
            "id": job_id,
            "status": "running",
            "query": self.query,
            "mode": self.mode,
            "steps": steps,
            "result": None,
            "error": None
        };

        _run_query_sync(job_id);

        report {
            "job_id": job_id,
            "status": _query_jobs[job_id]["status"],
            "steps": _query_jobs[job_id]["steps"]
        };
    }
}

# Poll a running query job for status and result.
walker:pub QueryStatus {
    has job_id: str;

    can check with Root entry {
        job = _query_jobs.get(self.job_id);
        if job is None {
            report {"error": "Query job not found.", "job_id": self.job_id};
            return;
        }
        report {
            "job_id": self.job_id,
            "status": job["status"],
            "query": job["query"],
            "mode": job["mode"],
            "steps": job["steps"],
            "result": job["result"],
            "error": job["error"]
        };
    }
}

def _set_step(job: dict, key: str, status: str, detail: str = "") -> None {
    for step in job["steps"] {
        if step["key"] == key {
            step["status"] = status;
            if detail {
                step["detail"] = detail;
            }
            break;
        }
    }
}

# Execute the query pipeline synchronously.
def _run_query_sync(job_id: str) -> None {
    state = get_state();
    job = _query_jobs[job_id];
    query = job["query"];
    mode = job["mode"];
    logger = logging.getLogger("spatialMind");

    def progress_cb(step_key: str, status: str, detail: str = "") -> None {
        _set_step(job, step_key, status, detail);
    }

    try {
        if gemini_enabled(state) {
            try {
                agent = GeminiSceneAgent(state=state, progress_cb=progress_cb);
                payload = agent.run(query=query, mode=mode);
            } except Exception as exc {
                logger.warning("Gemini agent failed; falling back: %s", exc);
                result = ground_query(
                    text=query, state=state,
                    persist_instances=True, progress_cb=progress_cb
                );
                payload = format_dense_payload(
                    result, mode=mode, query=query,
                    answer=result.get("answer", "")
                );
                payload["agent_fallback"] = True;
            }
        } else {
            result = ground_query(
                text=query, state=state,
                persist_instances=True, progress_cb=progress_cb
            );
            payload = format_dense_payload(
                result, mode=mode, query=query,
                answer=result.get("answer", "")
            );
            if mode == "edit" {
                color = _parse_color(query);
                matched = result.get("nodes", []);
                target_label = matched[0].get("label", "unknown") if matched else "unknown";
                payload.update({
                    "action": "recolor",
                    "target": target_label,
                    "color": color,
                    "matched_gaussians": result.get("highlight_indices", []),
                    "matched_nodes": [
                        {"label": n.get("label", ""), "confidence": 0.9}
                        for n in matched
                    ],
                    "answer": f"Done! I've changed the {target_label} to {color}.",
                    "description": f"Done! I've changed the {target_label} to {color}."
                });
            }
        }
        job["result"] = payload;
        job["status"] = "complete";
    } except Exception as exc {
        logger.exception("Query job failed: %s", exc);
        job["status"] = "error";
        job["error"] = str(exc);
    }
}

# Return grounded highlight regions for a text query.
walker:pub Highlight {
    has text: str;

    can compute with Root entry {
        state = get_state();
        gs = state.get("gaussian_store");
        ce = state.get("clip_encoder");

        if not gs or not ce {
            report {"error": "CLIP pipeline not ready."};
            return;
        }

        result = ground_query(text=self.text, state=state, persist_instances=True);
        report {
            "regions": result.get("highlight_regions", []),
            "indices": result.get("highlight_match", {}).get("indices", []),
            "scores": result.get("highlight_match", {}).get("scores", []),
            "total_matched": len(result.get("highlight_indices", [])),
            "cluster_count": len(result.get("highlight_regions", [])),
            "level": 2,
            "level_name": "sem2",
            "query": self.text,
            "threshold": result.get("highlight_match", {}).get("used_threshold"),
            "semantic_fallback": result.get("semantic_fallback", False)
        };
    }
}

# Probability cloud heatmap with multi-level support.
walker:pub Probability {
    has text: str;
    has level: int = 0;
    has temperature: float = 0.07;

    can compute with Root entry {
        state = get_state();
        gs = state.get("gaussian_store");
        ce = state.get("clip_encoder");

        if not gs or not ce {
            report {"error": "CLIP pipeline not ready."};
            return;
        }

        embeddings = gs.get_embeddings(self.level);
        if embeddings is None {
            report {"error": f"Semantic level {self.level} not loaded."};
            return;
        }

        text_emb = ce.encode_text(self.text);
        scores = prob_cloud(text_emb, embeddings, temperature=self.temperature);
        report {"scores": scores.tolist(), "level": self.level};
    }
}

# Return path to scene file for static serving.
walker:pub SceneSplat {
    can serve with Root entry {
        path = serve_scene_file();
        if path {
            report {"path": path, "status": "ok"};
        } else {
            report {"error": "No scene file found.", "status": "error"};
        }
    }
}

walker:pub ListScenes {
    can list with Root entry {
        report [
            {
                "id": "default",
                "name": "Modern Living Room",
                "status": "ready",
                "object_count": 12,
                "splat_url": "/api/scene/splat"
            }
        ];
    }
}

# Handle scene editing queries like 'change the couch to red'.
walker:pub EditScene {
    has query: str;

    can edit with Root entry {
        state = get_state();
        if not self.query.strip() {
            report {"error": "Query must be non-empty."};
            return;
        }

        result = ground_query(text=self.query, state=state, persist_instances=True);
        color = _parse_color(self.query);
        matched = result.get("nodes", []);
        target_label = matched[0].get("label", "unknown") if matched else "unknown";

        report {
            "action": "recolor",
            "target": target_label,
            "color": color,
            "matched_gaussians": result.get("highlight_indices", []),
            "matched_nodes": [
                {"label": n.get("label", ""), "confidence": 0.9}
                for n in matched
            ],
            "highlight_regions": result.get("highlight_regions", []),
            "highlight_match": result.get("highlight_match", {"indices": [], "scores": [], "level": 2}),
            "answer": f"Done! I've changed the {target_label} to {color}."
        };
    }
}

walker:pub MemoryStatus {
    has session_id: str = "demo";

    can check with Root entry {
        report {
            "room_summary": "Scene explored",
            "changes_detected": 0
        };
    }
}

def _parse_color(query: str) -> str {
    lower = query.lower();
    color_map = {
        "red": "#ff0000", "blue": "#0000ff", "green": "#00ff00",
        "yellow": "#ffff00", "orange": "#ff8800", "purple": "#8800ff",
        "pink": "#ff69b4", "white": "#ffffff", "black": "#000000",
        "brown": "#8b4513", "gray": "#808080", "grey": "#808080",
        "gold": "#ffd700", "cyan": "#00ffff", "magenta": "#ff00ff",
        "teal": "#008080"
    };
    for item in color_map.items() {
        name = item[0];
        hex_val = item[1];
        if name in lower {
            return hex_val;
        }
    }
    return "#ff0000";
}

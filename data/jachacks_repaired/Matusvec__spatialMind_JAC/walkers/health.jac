# Health check walker.

import from graph.types { SceneRoot }
import from services.py_bridge { get_state }
import from server.services.gemini_agent { gemini_enabled }

walker:pub HealthCheck {
    can check with Root entry {
        state = get_state();
        gs = state.get("gaussian_store");
        ce = state.get("clip_encoder");
        ig = state.get("instance_graph");
        ply_loaded = gs.is_loaded if gs else False;
        clip_ready = ce is not None;
        graph_nodes = len(ig.get("nodes", [])) if isinstance(ig, dict) else 0;
        graph_ready = graph_nodes > 0;
        pipeline_ready = ply_loaded and clip_ready;
        agent_ready = gemini_enabled(state);

        report {
            "status": "ok",
            "ply_loaded": ply_loaded,
            "autoencoder_initialized": state.get("autoencoder") is not None,
            "gaussian_count": gs.count if gs and ply_loaded else 0,
            "clip_ready": clip_ready,
            "scene_graph_ready": graph_ready,
            "scene_graph_nodes": graph_nodes,
            "instance_graph_ready": graph_ready,
            "instance_graph_nodes": graph_nodes,
            "pipeline_ready": pipeline_ready,
            "agent_ready": agent_ready,
            "agent_provider": "gemini" if agent_ready else None,
            "scene_source": state.get("scene_source", "none")
        };
    }
}

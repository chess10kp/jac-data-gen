# Python compute bridge.
# All Python interop goes through this module. JAC walkers call these
# functions to access numpy/torch/sklearn compute without importing
# Python directly. This is the ONLY place Python is called from JAC.

import os;
import time;
import logging;
import numpy as np;
import torch;
import uuid;
import glob as glob_mod;

import from server.config { Settings }
import from server.services.clip_encoder { CLIPEncoder }
import from server.services.gaussian_store { GaussianStore }
import from server.models.autoencoder { load_autoencoder }
import from server.services.dense_query { ground_query, build_highlight_regions }
import from server.services.query_node_builder { build_query_nodes }
import from server.services.spatial_relations { extract_spatial_relations, build_hierarchy }
import from server.services.scene_matching { lexical_score, tokenize, node_embedding }
import from server.services.similarity {
    highlight_mask,
    probability_cloud,
    relevancy_scores,
    CANONICAL_NEGATIVES
}
import from server.services.instance_cache {
    upsert_query_nodes,
    build_instance_graph,
    empty_instance_store
}
import from server.services.gemini_agent {
    GeminiSceneAgent,
    format_dense_payload,
    gemini_enabled,
    init_agent_steps
}

glob app_state: dict = {};

"""Load all artifacts and initialize app state. Replaces FastAPI lifespan."""
def initialize_app() -> dict {
    logger = logging.getLogger("spatialMind");
    start_time = time.time();
    config = Settings();

    device = config.device;
    logger.info("Device: %s", device);
    logger.info("Scene directory: %s", config.scene_dir);

    # Load autoencoder
    autoencoder = None;
    ae_candidates = [
        os.path.join(config.scene_dir, "autoencoder.pth"),
        os.path.join(config.scene_dir, "artifacts", "autoencoder.pth"),
        os.path.join(config.scene_dir, "ae_ckpt", "best_ckpt.pth")
    ];
    for ae_path in ae_candidates {
        if os.path.exists(ae_path) {
            try {
                autoencoder = load_autoencoder(ae_path, device);
                logger.info("Autoencoder loaded from: %s", ae_path);
                break;
            } except Exception as exc {
                logger.warning("Failed to load autoencoder from %s: %s", ae_path, exc);
            }
        }
    }

    # Load Gaussian store
    gaussian_store = GaussianStore(config);
    scene_source = "none";

    sem0_path = os.path.join(config.scene_dir, "semantic_0.ply");
    if os.path.exists(sem0_path) {
        try {
            gaussian_store.load_ply(sem0_path);
            scene_source = "live";
            for level in [1, 2] {
                sem_path = os.path.join(config.scene_dir, f"semantic_{level}.ply");
                if os.path.exists(sem_path) {
                    try {
                        gaussian_store.load_semantic_level(sem_path, level);
                    } except Exception as exc {
                        logger.warning("Failed to load semantic_%d.ply: %s", level, exc);
                    }
                }
            }
        } except Exception as exc {
            logger.warning("Failed to load semantic_0.ply: %s", exc);
        }
    }

    if not gaussian_store.is_loaded {
        search_pairs = [
            [os.path.join(config.scene_dir, "artifacts"), "live"],
            [os.path.join(config.fallback_scene_dir, "artifacts"), "fallback"]
        ];
        for pair in search_pairs {
            search_dir = pair[0];
            source_label = pair[1];
            ply_path = os.path.join(search_dir, "point_cloud.ply");
            if os.path.exists(ply_path) {
                try {
                    gaussian_store.load_ply(ply_path);
                    scene_source = source_label;
                    break;
                } except Exception as exc {
                    logger.warning("Failed to load PLY from %s: %s", ply_path, exc);
                }
            }
        }
    }

    # Decode embeddings
    if autoencoder and gaussian_store.latent_features is not None {
        try {
            gaussian_store.decode_all(autoencoder, device);
            gaussian_store.decoded_levels[0] = gaussian_store.decoded_embeddings;
            for level in [1, 2] {
                if level in gaussian_store.semantic_levels {
                    gaussian_store.get_embeddings(level, autoencoder=autoencoder, device=device);
                }
            }
        } except Exception as exc {
            logger.warning("Failed to decode Gaussians: %s", exc);
        }
    }

    # Load CLIP encoder
    clip_encoder: any = None;
    negative_embeddings = None;
    try {
        clip_encoder = CLIPEncoder(config.clip_model, config.clip_pretrained, device);
        negative_embeddings = np.stack([
            clip_encoder.encode_text(neg) for neg in CANONICAL_NEGATIVES
        ]);
    } except Exception as exc {
        logger.warning("Failed to load CLIP encoder: %s", exc);
    }

    state = {
        "config": config,
        "autoencoder": autoencoder,
        "gaussian_store": gaussian_store,
        "clip_encoder": clip_encoder,
        "scene_graph": None,
        "instance_graph": {
            "nodes": [],
            "edges": [],
            "hierarchy": [],
            "metadata": {"node_count": 0, "edge_count": 0, "hierarchy_count": 0, "source": "instance-cache"}
        },
        "instance_store": empty_instance_store(),
        "memory_service": None,
        "exploration_catalog": None,
        "scene_source": scene_source,
        "negative_embeddings": negative_embeddings
    };

    elapsed = time.time() - start_time;
    logger.info(
        "Startup complete in %.1fs | Gaussians: %d | Device: %s",
        elapsed, gaussian_store.count, device
    );

    app_state = state;
    return state;
}

def get_state() -> dict {
    return app_state;
}

"""Run the dense grounding pipeline via Python."""
def bridge_ground_query(text: str, persist: bool = True, preferred_levels: tuple = (0, 1, 2)) -> dict {
    return ground_query(
        text=text,
        state=app_state,
        persist_instances=persist,
        preferred_levels=preferred_levels
    );
}

"""Compute lexical match score between query and label."""
def bridge_lexical_score(query: str, label: str) -> float {
    return lexical_score(query, label);
}

"""Compute per-Gaussian highlight mask."""
def bridge_highlight_mask(text: str, mode: str = "soft") -> list {
    gs = app_state.get("gaussian_store");
    ce = app_state.get("clip_encoder");
    if not gs or not ce or gs.decoded_embeddings is None {
        return [];
    }
    text_emb = ce.encode_text(text);
    mask = highlight_mask(text_emb, gs.decoded_embeddings, mode=mode);
    return mask.tolist();
}

"""Compute per-Gaussian probability scores."""
def bridge_probability_cloud(text: str, level: int = 0, temperature: float = 0.07) -> list {
    gs = app_state.get("gaussian_store");
    ce = app_state.get("clip_encoder");
    if not gs or not ce {
        return [];
    }
    embeddings = gs.get_embeddings(level);
    if embeddings is None {
        return [];
    }
    text_emb = ce.encode_text(text);
    scores = probability_cloud(text_emb, embeddings, temperature=temperature);
    return scores.tolist();
}

"""Rebuild the instance graph from current cache."""
def bridge_build_instance_graph() -> dict {
    store = app_state.get("instance_store");
    gs = app_state.get("gaussian_store");
    if store is None {
        return {"nodes": [], "edges": [], "hierarchy": [], "metadata": {}};
    }
    graph = build_instance_graph(store, gs);
    app_state["instance_graph"] = graph;
    return graph;
}

"""Get mean CLIP embedding for a node."""
def bridge_node_embedding(node_dict: dict) -> list {
    gs = app_state.get("gaussian_store");
    emb = node_embedding(node_dict, gs);
    if emb is not None {
        return emb.tolist();
    }
    return [];
}

"""Find and return path to scene file for static serving."""
def serve_scene_file() -> str {
    config = app_state.get("config");
    if config is None {
        return "";
    }
    artifacts_dir = os.path.join(config.scene_dir, "artifacts");
    for ext in ["*.splat", "*.ply", "*.spz", "*.ksplat"] {
        files = glob_mod.glob(os.path.join(artifacts_dir, ext));
        if files {
            return os.path.realpath(files[0]);
        }
    }
    return "";
}

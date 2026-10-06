"""SpatialMind — JAC entry point.

Replaces server/main.py (298 lines). Imports all graph types, walkers,
and Python bridge, then initializes the application state on startup.

Run with: jac serve main.jac --port 8001
"""

import from graph.types {
    SceneRoot, SceneObject, SpatialRelation, SemanticHierarchy, Contains, JobStatus
}
import from services.py_bridge { initialize_app, get_state }
import from walkers.health { HealthCheck }
import from walkers.explore { ExploreScene, ExploreStatus }
import from walkers.query {
    QueryDirect, QueryStart, QueryStatus,
    Highlight, Probability, SceneSplat, ListScenes,
    EditScene, MemoryStatus
}
import from walkers.upsert { UpsertInstances }
import from walkers.spatial { BuildSpatialRelations }
import from walkers.chat { ChatQuery }

with entry {
    # Initialize Python compute services (load PLY, autoencoder, CLIP)
    state = initialize_app();

    # Create the scene root node in the JAC graph
    gs = state.get("gaussian_store");
    scene_root = SceneRoot(
        scene_id="default",
        gaussian_count=int(gs.count) if gs else 0,
        scene_source=str(state.get("scene_source", "none"))
    );
    root ++> scene_root;
}

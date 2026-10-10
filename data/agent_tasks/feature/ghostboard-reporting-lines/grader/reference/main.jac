"""GHOST BOARD — Main Entry Point.

Orchestrates the full-stack Jac application.
"""

import time;
import from .server { initialize_graph, SyncSystemStatus }
import from .client { CommandCenter }

# -----------------------------------------------------------------------------
# Server Entry Point
# -----------------------------------------------------------------------------

def sync_loop() {
    while True {
        root spawn SyncSystemStatus();
        time.sleep(5);
    }
}

with entry {
    # 1. Initialize the Knowledge Graph (if on server)
    initialize_graph();

    # 2. Start background orchestration walkers
    # Sync metrics every 5 seconds
    flow sync_loop();

    print("Ghost Board Server Initialized.");
}

# -----------------------------------------------------------------------------
# Client Entry Point
# -----------------------------------------------------------------------------

def:pub app() -> JsxElement {
    return <CommandCenter />;
}

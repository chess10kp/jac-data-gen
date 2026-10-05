# Main entry point for DevOpsAudit prototype
# Import module files
import config;
import integrations;
import from architecture { InitGraph }
import from agents { TopologySentinel }

walker Main {
    can run with Root entry {
        print("[MAIN] Initializing graph and starting audit workflow");

        if config.env == "prod" {
            integrations.fetch_aws_state();
        } else {
            # Initialize the graph from mock data
            root spawn InitGraph();
        }

        # Trigger sentinel to detect drifts
        root spawn TopologySentinel();
    }
}

with entry {
    root spawn Main();
}

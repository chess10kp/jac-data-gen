# main.jac — GhostWatch entry point.
# jac start main.jac exposes all walker:pub endpoints automatically.

import from ghostwatch_walker_imports { ghostwatch_walkers_registered }
import from graph.builder { GraphBuilderWalker }
import from walkers.static.orchestrator { OrchestratorWalker }
import from walkers.static.graph_state { GraphStateWalker }
import from walkers.ghostwatch.github_system2_webhook { GitHubSystem2WebhookWalker }
import from walkers.ghostwatch.system2_hooks { System2PushTriggerWalker, System2MergeTriggerWalker, System2EscalationTickWalker }
import from os { environ }
import from integrations.github { validate_webhook_signature }
import from dotenv { load_dotenv }

walker:pub GitHubWebhookWalker {
    has event_type: str;
    has payload: dict;
    has signature: str = "";

    can handle with Root entry {
        secret = environ.get("GITHUB_WEBHOOK_SECRET", "");
        if secret and self.signature {
            payload_bytes: bytes = str(self.payload).encode();
            if not validate_webhook_signature(payload_bytes, self.signature, secret) {
                report {"error": "Invalid webhook signature", "status": 401};
                return;
            }
        }

        if self.event_type == "pull_request" {
            action = self.payload.get("action", "");
            if action in ["opened", "synchronize", "reopened", "edited"] {
                pr = self.payload.get("pull_request", {});
                pr_url: str = str(pr.get("html_url", ""));
                if pr_url {
                    root spawn OrchestratorWalker(pr_url=pr_url);
                    report {"status": "analysis_triggered", "pr_url": pr_url};
                    return;
                }
            }
        }

        report {"status": "webhook_received", "event": self.event_type};
    }
}

with entry {
    _ = load_dotenv();
    _wl = ghostwatch_walkers_registered();
    print("GhostWatch System 1 ready.");
    print("Step 1: POST /walker/GraphBuilderWalker to build the codebase graph.");
    print("Step 2: Configure GitHub webhook -> POST /walker/git-hub-webhook-walker");
}

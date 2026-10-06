# walkers/ghostwatch/impl/github_system2_webhook.impl.jac

import from os { environ }
import from integrations.github { validate_webhook_signature, list_commit_files, get_parent_commit_sha }
import from walkers.ghostwatch.dep_diff { DependencyDiffWalker }
import from walkers.ghostwatch.gap_analysis { GapAnalysisWalker }

impl GitHubSystem2WebhookWalker.run with Root entry {
    secret = environ.get("GITHUB_WEBHOOK_SECRET", "");
    if secret and self.signature and self.raw_body {
        payload_bytes = self.raw_body.encode("utf-8");
        if not validate_webhook_signature(payload_bytes, self.signature, secret) {
            report {"status": 401, "error": "Invalid webhook signature"};
            return;
        }
    }
    ev = self.event_type;
    if ev == "push" {
        repo_obj = self.payload.get("repository", {});
        repo_full = str(repo_obj.get("full_name", ""));
        commit_sha = str(self.payload.get("after", ""));
        if not repo_full or not commit_sha {
            report {"status": "ignored", "reason": "missing repo or after sha"};
            return;
        }
        parent_sha = get_parent_commit_sha(repo_full, commit_sha);
        files = list_commit_files(repo_full, commit_sha);
        manifests = [];
        for f in files {
            fs = str(f);
            is_m = False;
            if fs.endswith("package.json") {
                is_m = True;
            }
            if fs.endswith("requirements.txt") {
                is_m = True;
            }
            if fs.endswith("pyproject.toml") {
                is_m = True;
            }
            if fs.endswith("jac.toml") {
                is_m = True;
            }
            if is_m {
                manifests.append(fs);
            }
        }
        if manifests {
            _ = root spawn DependencyDiffWalker(
                repo_full_name=repo_full,
                commit_sha=commit_sha,
                parent_sha=parent_sha,
                manifest_paths=manifests
            );
            report {"status": "dependency_diff_dispatched", "manifest_count": len(manifests)};
            return;
        }
        report {"status": "push_no_manifest"};
        return;
    }
    if ev == "pull_request" {
        action = str(self.payload.get("action", ""));
        repo_full = "";
        merge_sha = "";
        try {
            pr = self.payload["pull_request"];
            merged = pr["merged"];
            if action == "closed" and merged {
                brepo = pr["base"]["repo"];
                repo_full = str(brepo["full_name"]);
                merge_sha = str(pr["merge_commit_sha"]);
            }
        } except Exception {
            repo_full = "";
            merge_sha = "";
        }
        if repo_full and merge_sha {
            _ = root spawn GapAnalysisWalker(repo_full_name=repo_full, merge_commit_sha=merge_sha);
            report {"status": "gap_analysis_dispatched"};
            return;
        }
        report {"status": "pr_ignored", "action": action};
        return;
    }
    report {"status": "noop", "event": ev};
}

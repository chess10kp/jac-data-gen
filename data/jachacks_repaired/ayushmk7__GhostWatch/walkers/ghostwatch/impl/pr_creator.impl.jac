# walkers/ghostwatch/impl/pr_creator.impl.jac

import from graph.nodes { GhostwatchIncidentNode }
import from integrations.github {
    create_branch_from_sha,
    update_file_on_branch,
    open_pull_request,
    get_default_branch,
    get_branch_head_sha
}
import from integrations.discord { notify_discord_incident }
import from time { time }
import threading;

impl GhostwatchPRCreatorWalker._format_pr_body(incident: dict) -> str {
    dep = str(incident.get("dependency_name", ""));
    return f"## GhostWatch auto-fix\nDependency: `{dep}`\n";
}

def _escalation_job(jid_arg: str) -> None {
    print(f"GhostWatch escalation tick for {jid_arg}");
}

impl GhostwatchPRCreatorWalker.run with Root entry {
    for target in [root -->][?:GhostwatchIncidentNode] {
        if str(jid(target)) != self.incident_jid {
            continue;
        }
        if target.fix_pr_url {
            report {"status": "idempotent_skip", "pr": target.fix_pr_url};
            return;
        }
        base = get_default_branch(target.repo_full_name);
        head_sha = get_branch_head_sha(target.repo_full_name, base);
        if not head_sha {
            report {"error": "no head sha"};
            return;
        }
        ts = int(time());
        safe_dep = target.dependency_name.replace("/", "-").replace("@", "")[:40];
        branch = f"ghostwatch/auto-fix-{safe_dep}-{ts}";
        create_branch_from_sha(target.repo_full_name, branch, head_sha);
        update_file_on_branch(
            target.repo_full_name,
            target.manifest_path,
            branch,
            self.validated_fix_content,
            f"GhostWatch: remove/repair {target.dependency_name}"
        );
        inc_dict = {
            "dependency_name": target.dependency_name,
            "manifest_path": target.manifest_path,
            "sandbox_result": target.sandbox_result,
            "behavioral_trace": target.behavioral_trace,
            "rule_codes": target.rule_codes
        };
        try {
            body = self._format_pr_body(incident=inc_dict);
        } except Exception {
            body = f"## GhostWatch auto-fix\nDependency: `{target.dependency_name}`\nManifest: `{target.manifest_path}`\n";
        }
        pr_url = open_pull_request(
            target.repo_full_name,
            f"GhostWatch: address malicious dependency {target.dependency_name}",
            body,
            branch,
            base
        );
        target.fix_pr_url = pr_url;
        target.fix_branch_name = branch;
        target.alert_state = "pr_opened";
        target.updated_at = str(ts);
        target.next_escalation_at = str(ts + 7200);
        notify_discord_incident(
            {
                "dependency_name": target.dependency_name,
                "status": "malicious_with_fix_pr",
                "repo": target.repo_full_name,
                "summary": pr_url
            }
        );
        t = threading.Timer(7200.0, _escalation_job, args=[self.incident_jid]);
        t.daemon = True;
        t.start();
        report {"pr_url": pr_url, "branch": branch};
        return;
    }
    report {"error": "incident not found"};
}

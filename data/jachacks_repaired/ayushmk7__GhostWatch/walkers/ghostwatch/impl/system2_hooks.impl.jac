# walkers/ghostwatch/impl/system2_hooks.impl.jac

import from walkers.ghostwatch.dep_diff { DependencyDiffWalker }
import from walkers.ghostwatch.gap_analysis { GapAnalysisWalker }
import from graph.nodes { GhostwatchIncidentNode }
import from integrations.discord { notify_discord_escalation }
import from time { time }

impl System2PushTriggerWalker.run with Root entry {
    _ = root spawn DependencyDiffWalker(
        repo_full_name=self.repo_full_name,
        commit_sha=self.commit_sha,
        parent_sha=self.parent_sha,
        manifest_paths=self.manifest_paths
    );
    report {"status": "push_dispatched"};
}

impl System2MergeTriggerWalker.run with Root entry {
    _ = root spawn GapAnalysisWalker(repo_full_name=self.repo_full_name, merge_commit_sha=self.merge_commit_sha);
    report {"status": "merge_dispatched"};
}

impl System2EscalationTickWalker.run with Root entry {
    now = str(int(time()));
    for inc in [root -->][?:GhostwatchIncidentNode] {
        if inc.next_escalation_at and inc.next_escalation_at <= now and inc.alert_state != "escalated" {
            notify_discord_escalation({"dedupe_key": inc.dedupe_key, "note": "Follow up on incident"});
            inc.alert_state = "escalated";
        }
    }
    report {"status": "escalation_sweep"};
}

# walkers/ghostwatch/impl/fix_gen.impl.jac

import from graph.nodes { GhostwatchIncidentNode }
import from integrations.github { fetch_file_content, get_parent_commit_sha }
import from lib.manifest { fix_invert_manifest }
import from lib.sandbox_exec { run_manifest_body_sandbox }
import from walkers.ghostwatch.pr_creator { GhostwatchPRCreatorWalker }
import from time { time }

impl FixGenerationWalker._explain_fix(incident: dict) -> str {
    return "GhostWatch fix (LLM stub)";
}

impl FixGenerationWalker.run with Root entry {
    for target in [root -->][?:GhostwatchIncidentNode] {
        if str(jid(target)) != self.incident_jid {
            continue;
        }
        psha = get_parent_commit_sha(target.repo_full_name, target.commit_sha);
        par = fetch_file_content(target.repo_full_name, target.manifest_path, psha);
        cur = fetch_file_content(target.repo_full_name, target.manifest_path, target.commit_sha);
        fixed = fix_invert_manifest(target.manifest_path, par, cur, target.dependency_name);
        mp = str(target.manifest_path);
        val_raw = run_manifest_body_sandbox(mp, fixed);
        passed = val_raw.get("install_ok", False);
        if passed {
            _ = root spawn GhostwatchPRCreatorWalker(incident_jid=self.incident_jid, validated_fix_content=fixed);
        }
        target.updated_at = str(int(time()));
        report {"fix_validated": passed};
        return;
    }
    report {"error": "incident not found"};
}

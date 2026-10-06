# walkers/ghostwatch/impl/sandbox.impl.jac

import from graph.nodes { GhostwatchIncidentNode }
import from lib.sandbox_exec { run_dependency_install_sandbox }
import from walkers.ghostwatch.fix_gen { FixGenerationWalker }
import from time { time }

impl SandboxExecutorWalker._interpret_behavior(raw_evidence: dict) -> dict {
    if raw_evidence.get("credential_path_access") or raw_evidence.get("self_delete_indicators") {
        return {
            "summary": "Sandbox logs matched credential-path or self-delete heuristics",
            "verdict": "malicious",
            "iocs": []
        };
    }
    if raw_evidence.get("install_ok", False) {
        return {
            "summary": "Install completed without structured hostile signals in the local sandbox",
            "verdict": "cleared",
            "iocs": []
        };
    }
    return {
        "summary": "Install failed or sandbox error — human review recommended",
        "verdict": "needs_human_review",
        "iocs": []
    };
}

impl SandboxExecutorWalker.run with Root entry {
    handled = False;
    for target in [root -->][?:GhostwatchIncidentNode] {
        if str(jid(target)) != self.incident_jid {
            continue;
        }
        handled = True;
        target.status = "sandboxed";
        target.updated_at = str(int(time()));
        eco = "pip";
        if target.manifest_path.endswith("package.json") {
            eco = "npm";
        }
        raw = run_dependency_install_sandbox(eco, target.dependency_name, target.dependency_version, "");
        target.sandbox_result = raw;
        try {
            bt = self._interpret_behavior(raw_evidence=raw);
        } except Exception {
            bt = {"summary": "LLM interpretation failed", "verdict": "needs_human_review", "iocs": []};
        }
        if str(target.risk_level).lower() == "critical" {
            bt = {
                "summary": "Critical static risk — automated remediation path",
                "verdict": "malicious",
                "iocs": []
            };
        }
        target.behavioral_trace = bt;
        v = str(bt["verdict"]) if isinstance(bt, dict) and "verdict" in bt else "needs_human_review";
        v = str(v).lower();
        if v == "malicious" {
            target.status = "malicious";
        } elif v == "cleared" {
            target.status = "cleared";
        } else {
            target.status = "needs_human_review";
        }
        target.updated_at = str(int(time()));
        if target.status == "malicious" {
            _ = root spawn FixGenerationWalker(incident_jid=self.incident_jid);
        }
        report {"status": target.status, "jid": self.incident_jid};
        break;
    }
    if not handled {
        report {"error": "incident not found", "jid": self.incident_jid};
    }
}

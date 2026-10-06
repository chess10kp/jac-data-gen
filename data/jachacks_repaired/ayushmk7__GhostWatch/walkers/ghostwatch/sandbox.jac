# walkers/ghostwatch/sandbox.jac — Sandbox flagged dependency, update incident.

import from graph.nodes { GhostwatchIncidentNode }

walker:pub SandboxExecutorWalker {
    has incident_jid: str;
    has reports: list = [];

    can run with Root entry;

    def _interpret_behavior(raw_evidence: dict) -> dict;
}

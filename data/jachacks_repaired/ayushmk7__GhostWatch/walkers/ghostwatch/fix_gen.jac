# walkers/ghostwatch/fix_gen.jac — Deterministic manifest fix + validation sandbox.

import from graph.nodes { GhostwatchIncidentNode }

walker:pub FixGenerationWalker {
    has incident_jid: str;
    has reports: list = [];

    can run with Root entry;

    def _explain_fix(incident: dict) -> str;
}

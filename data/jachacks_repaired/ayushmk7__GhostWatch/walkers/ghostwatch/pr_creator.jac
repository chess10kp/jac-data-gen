# walkers/ghostwatch/pr_creator.jac — Branch, commit manifest fix, open PR, Discord.

import from graph.nodes { GhostwatchIncidentNode }

walker:pub GhostwatchPRCreatorWalker {
    has incident_jid: str;
    has validated_fix_content: str;
    has reports: list = [];

    can run with Root entry;

    def _format_pr_body(incident: dict) -> str;
}

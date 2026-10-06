# Chat walker with by llm() integration.
# Replaces server/services/gemini_agent.py (~382 lines) with JAC's native
# by llm() for intent classification and tool dispatch.

import from graph.types { SceneRoot, SceneObject }
import from services.py_bridge { get_state }
import from server.services.dense_query { ground_query }
import from server.services.gemini_agent { format_dense_payload }
import logging;

enum Intent {
    FIND = "find",
    HIGHLIGHT = "highlight",
    RECOLOR = "recolor",
    DESCRIBE = "describe",
    NAVIGATE = "navigate"
}

# AI agent that interprets natural language and executes scene tools.
# Uses by llm() for intent classification and answer generation,
# delegating to Python compute for actual grounding.
walker:pub ChatQuery {
    has query: str;
    has mode: str = "query";

    can classify_intent
    with Root entry by llm(
        incl_info=(self.query,),
        reason=True
    );

    can generate_answer
    with Root entry by llm(
        incl_info=(self.query,),
        reason=True
    );

    can process with Root entry {
        logger = logging.getLogger("spatialMind");
        state = get_state();

        intent = self.classify_intent;
        logger.info("Chat intent: %s for query: %s", intent, self.query);

        result = ground_query(text=self.query, state=state, persist_instances=True);
        nodes = result.get("nodes", []);
        labels = [n.get("label", "region") for n in nodes[:6]];

        context_parts = [];
        for n in nodes {
            centroid = n.get("centroid", [0, 0, 0]);
            cx = centroid[0];
            cy = centroid[1];
            cz = centroid[2];
            context_parts.append(
                f"{n.get('label', 'unknown')} at ({cx:.1f}, {cy:.1f}, {cz:.1f})"
            );
        }
        context = "\n".join(context_parts) if context_parts else "No objects found.";

        answer = str(context);

        payload = format_dense_payload(
            result,
            mode=self.mode,
            query=self.query,
            answer=answer or result.get("answer", "")
        );

        if intent == Intent.HIGHLIGHT {
            payload["highlight_color"] = "#7c3aed";
        } elif intent == Intent.RECOLOR {
            color = _extract_color(self.query);
            target_label = labels[0] if labels else "region";
            payload.update({
                "action": "recolor",
                "target": target_label,
                "color": color,
                "matched_gaussians": result.get("highlight_indices", []),
                "matched_nodes": [
                    {"label": l, "confidence": 0.9} for l in labels
                ]
            });
        }

        payload["agent_provider"] = "jac-byllm";
        report payload;
    }
}

# Extract color from query text.
def _extract_color(query: str) -> str {
    lower = query.lower();
    colors = {
        "red": "#ff0000", "blue": "#0000ff", "green": "#00ff00",
        "yellow": "#ffff00", "orange": "#ff8800", "purple": "#8800ff",
        "pink": "#ff69b4", "white": "#ffffff", "black": "#000000"
    };
    for item in colors.items() {
        name = item[0];
        hex_val = item[1];
        if name in lower {
            return hex_val;
        }
    }
    return "#7c3aed";
}

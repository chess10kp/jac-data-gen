# NeuroFlow agent workflow — LLM-powered, local & free (byllm + Ollama).
# jaclang 0.15.2 / byllm. Two real LLM stages, no deterministic rules.
#
#   Stage 1: Context Agent  (LLM analyses behaviour)
#   Stage 2: Decision Agent (LLM decides the command)
#
# Enums grammar-constrain the small local model to valid values. Jac
# only assembles the final JSON shape (structural, not decision logic).
# Final stdout line is the decision JSON ONLY (the extension runs it).

import from byllm.llm { Model }
import json;
import os;

glob llm = Model("ollama/gemma2:2b");


enum RiskLevel { low, medium, high }

enum Pattern { productive, distracted, mixed }

enum Status { ok, distracted }


obj ContextOut {
    has behaviorSummary: str;
    has riskLevel: RiskLevel;
    has dominantPattern: Pattern;
    has evidence: list[str];
}


obj DecisionOut {
    has status: Status;
    has reason: str;
    has unlockDescription: str;
    has allowedHosts: list[str];
    has message: str;
}


"""
You are the NeuroFlow Context Agent. Analyse the user's browsing
behaviour from the JSON (currentSegment, recentSegments, rollingStats).
Detect doomscrolling: distracting/social/video sites, repeated
social/entertainment browsing, high distracting time, prolonged
short-form/feed content, context-switching loops. Use the recent
history, not just the current tab. Set dominantPattern, riskLevel, a
one-sentence behaviorSummary, and 2-4 short evidence strings citing
specific signals.
"""
def context_agent(packet_json: str) -> ContextOut by llm();


"""
You are the NeuroFlow Decision Agent. Given the context analysis and
the current segment, decide the command. status=ok if the user is
productive or only mildly distracted. status=distracted only if the
user is in a real distraction loop AND the current site is the problem.
For status=distracted, pick a concrete unlockDescription (e.g. 5
focused minutes on Google Docs / LeetCode / GitHub / Canvas) and the
allowedHosts that match it. Write a short reason and a short
user-facing message.
"""
def decision_agent(context_summary: str, current_json: str) -> DecisionOut by llm();


with entry {
    packet_path = os.environ.get("NEUROFLOW_PACKET");
    packet = {};
    if packet_path {
        with open(packet_path) as f {
            packet = json.load(f);
        }
    }
    current = packet.get("currentSegment") or {};

    ctx = context_agent(json.dumps(packet));
    print("[NeuroFlow:jac] CONTEXT LLM RAN");

    summary = "behaviorSummary: " + ctx.behaviorSummary
        + " | riskLevel: " + ctx.riskLevel.name
        + " | dominantPattern: " + ctx.dominantPattern.name
        + " | evidence: " + json.dumps(ctx.evidence);

    dec = decision_agent(summary, json.dumps(current));
    print("[NeuroFlow:jac] DECISION LLM RAN");

    # Assemble the EXACT spec shape. The LLM decided status/reason/
    # unlock/message; Jac only binds identity + structure.
    out: dict = {};
    if dec.status == Status.ok {
        out = {
            "status": "ok",
            "tabId": current.get("tabId"),
            "action": "none",
            "reason": dec.reason
        };
    } else {
        out = {
            "status": "distracted",
            "tabId": current.get("tabId"),
            "action": "restrict",
            "targetHost": current.get("host"),
            "reason": dec.reason,
            "unlockTask": {
                "description": dec.unlockDescription,
                "allowedHosts": dec.allowedHosts,
                "requiredDurationSeconds": 300
            },
            "message": dec.message
        };
    }

    print("[NeuroFlow:jac] REAL LLM AGENTS RAN");
    print(json.dumps(out));
}

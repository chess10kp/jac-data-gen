def:pub defaultModes() -> list[dict[str, str]] {
    return [
        {"key": "bug_fix", "label": "Bug Fix", "description": "Trace likely breakpoints, blockers, and repair scope."},
        {"key": "feature_plan", "label": "Feature Plan", "description": "Turn meeting context into an execution plan and tickets."},
        {"key": "standup", "label": "Standup", "description": "Summarize progress, next steps, and blockers."},
        {"key": "handoff", "label": "Handoff", "description": "Prepare the next developer with context and risks."},
        {"key": "review_prep", "label": "Review Prep", "description": "Frame review scope, hotspots, and checklist items."}
    ];
}

def:pub defaultTabs() -> list[dict[str, str]] {
    return [
        {"key": "context", "label": "Context"},
        {"key": "files", "label": "Files"},
        {"key": "tasks", "label": "Tasks"},
        {"key": "tickets", "label": "Tickets"},
        {"key": "blockers", "label": "Blockers"},
        {"key": "handoff", "label": "Handoff"},
        {"key": "standup", "label": "Standup"},
        {"key": "review", "label": "Review"},
        {"key": "memory", "label": "Memory"},
        {"key": "trace", "label": "Trace"}
    ];
}

def:pub quickPrompts() -> list[dict[str, str]] {
    return [
        {"mode": "bug_fix", "label": "Bug Fix", "prompt": "What blockers do you see and what should I inspect first?"},
        {"mode": "feature_plan", "label": "Feature Plan", "prompt": "Turn this meeting into tickets and likely files."},
        {"mode": "standup", "label": "Standup", "prompt": "Give me a concise standup update from the current context."},
        {"mode": "handoff", "label": "Handoff", "prompt": "Prepare a handoff with risks, touched areas, and next actions."},
        {"mode": "review_prep", "label": "Review Prep", "prompt": "Summarize review scope and risk hotspots for this work."}
    ];
}

def:pub shellTitle() -> str {
    return "RepoGhost";
}

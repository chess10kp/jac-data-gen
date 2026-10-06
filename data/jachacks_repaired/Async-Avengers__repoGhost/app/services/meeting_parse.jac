import from app.models.core { MeetingSummary, DecisionItem, BlockerItem }

def collect_lines(text: str) -> list[str] {
    return [line.strip() for line in text.split("\n") if line.strip()];
}

def replace_token(text: str, token: str, value: str) -> str {
    return text.replace(token, value);
}

def split_spaces(text: str) -> list[str] {
    return text.split(" ");
}

def normalize_words(text: str) -> list[str] {
    normalized_text: str = replace_token(text, ",", " ");
    normalized_text = replace_token(normalized_text, ".", " ");
    return split_spaces(normalized_text);
}

def short_text(text: str) -> str {
    trimmed: str = text.strip();
    return trimmed;
}

def lower_text(text: str) -> str {
    return text.lower();
}

def split_once_text(text: str, token: str) -> list[str] {
    return text.split(token, 1);
}

def cleaned_line(line: str) -> str {
    text: str = line.strip();
    if ":" in text {
        parts: list[str] = split_once_text(text, ":");
        if len(parts) > 1 and len(parts[0]) <= 28 {
            next_text: str = parts[1].strip();
            if next_text {
                return next_text;
            }
        }
    }
    return text;
}

def join_summary_parts(parts: list[str]) -> str {
    summary: str = "";
    for item in parts {
        if not item {
            continue;
        }
        if summary {
            summary = summary + " ";
        }
        summary = summary + item;
    }
    return summary;
}

def decision_title(text: str) -> str {
    lowered: str = lower_text(text);
    if "lock in" in lowered or "align" in lowered or "agreed" in lowered {
        return "Alignment";
    }
    if "lightweight" in lowered or "core features" in lowered or "scope" in lowered {
        return "Scope";
    }
    if "focus" in lowered or "priority" in lowered or "next step" in lowered {
        return "Priority";
    }
    return "Decision";
}

def blocker_title(text: str) -> str {
    lowered: str = lower_text(text);
    if "test" in lowered or "ready" in lowered {
        return "Validation blocker";
    }
    if "waiting" in lowered {
        return "Dependency blocker";
    }
    return "Blocker";
}

def build_summary(
    lines: list[str],
    action_items: list[str],
    decisions: list[DecisionItem],
    blockers: list[BlockerItem],
    systems: list[str]
) -> str {
    parts: list[str] = [];
    if len(decisions) > 0 {
        parts.append(short_text(cleaned_line(decisions[0].detail)));
    }
    if len(action_items) > 0 {
        parts.append("Next, " + short_text(cleaned_line(action_items[0])));
    }
    if len(blockers) > 0 {
        parts.append("Watch for " + short_text(cleaned_line(blockers[0].detail)));
    }
    if len(parts) == 0 and len(systems) > 0 {
        parts.append(short_text(cleaned_line(systems[0])));
    }
    if len(parts) == 0 {
        for line in lines {
            parts.append(short_text(cleaned_line(line)));
            if len(parts) >= 3 {
                break;
            }
        }
    }
    summary: str = join_summary_parts(parts[:3]);
    if summary {
        if not summary.endswith(".") {
            return summary + ".";
        }
        return summary;
    }
    return "Meeting context parsed from transcript input.";
}

def:pub parse_meeting(meeting_text: str) -> MeetingSummary {
    if not meeting_text {
        return MeetingSummary(summary="No meeting context provided.");
    }
    lines: list[str] = collect_lines(meeting_text);
    action_items: list[str] = [];
    decisions: list[DecisionItem] = [];
    blockers: list[BlockerItem] = [];
    people: list[str] = [];
    systems: list[str] = [];
    deadlines: list[str] = [];
    uncertainty: list[str] = [];
    for line in lines {
        normalized_line: str = cleaned_line(line);
        lowered = lower_text(normalized_line);
        if "todo" in lowered or "action" in lowered or "next" in lowered or "should" in lowered {
            action_items.append(normalized_line);
        }
        if "decide" in lowered or "decision" in lowered or "agreed" in lowered {
            decisions.append(DecisionItem(title=decision_title(normalized_line), detail=normalized_line, confidence=0.72, source="meeting"));
        }
        if "blocker" in lowered or "blocked" in lowered or "risk" in lowered or "waiting" in lowered {
            blockers.append(BlockerItem(title=blocker_title(normalized_line), detail=normalized_line, severity="medium", owner_hint="meeting"));
        }
        if "by friday" in lowered or "deadline" in lowered or "due" in lowered {
            deadlines.append(normalized_line);
        }
        if "maybe" in lowered or "unclear" in lowered or "not sure" in lowered {
            uncertainty.append(normalized_line);
        }
        if "api" in lowered or "ui" in lowered or "repo" in lowered or "workflow" in lowered or "memory" in lowered {
            systems.append(normalized_line);
        }
    }
    words: list[str] = normalize_words(meeting_text);
    for word in words {
        if len(word) > 1 and word[0].isupper() and word not in people and word.lower() not in ["we", "the", "repo", "workflow"] {
            people.append(word);
        }
    }
    if len(action_items) == 0 {
        for item in lines[:3] {
            action_items.append(cleaned_line(item));
        }
    }
    summary: str = build_summary(lines, action_items, decisions, blockers, systems);
    return MeetingSummary(summary=summary, action_items=action_items, decisions=decisions, blockers=blockers, people=people[:8], systems=systems[:8], deadlines=deadlines, uncertainty=uncertainty);
}
